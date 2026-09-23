import Foundation
import IOKit
import Darwin

/// Access only on SystemMonitorService's serial worker queue.
nonisolated final class SystemMetricsCollector: @unchecked Sendable {
    struct Snapshot {
        var cpu: CPUResult
        var memory: MemResult
        var network: NetResult
        var disk: DiskResult
        var gpu: GPUResult
        var temperature: Double
        var sampledUptime: TimeInterval
    }

    private(set) var pCoreCount = 0
    private(set) var eCoreCount = 0
    private(set) var memTotalGB = 0.0
    // MARK: - Private State
    private var prevCpuInfo: processor_info_array_t?
    private var prevCpuInfoCount: mach_msg_type_number_t = 0
    private var prevNetDown: UInt64 = 0
    private var prevNetUp: UInt64 = 0
    private var prevDiskRead: UInt64 = 0
    private var prevDiskWrite: UInt64 = 0
    private var prevNetUptime: TimeInterval?
    private var prevDiskUptime: TimeInterval?


    private let numLogicalCPUs: Int

    private var cachedGPUServices: [io_registry_entry_t] = []
    private var cachedDiskServices: [io_registry_entry_t] = []

    init() {
        numLogicalCPUs = ProcessInfo.processInfo.processorCount

        var pCount: Int = 0
        var pCountSize = MemoryLayout<Int>.size
        sysctlbyname("hw.perflevel0.logicalcpu", &pCount, &pCountSize, nil, 0)

        var eCount: Int = 0
        var eCountSize = MemoryLayout<Int>.size
        sysctlbyname("hw.perflevel1.logicalcpu", &eCount, &eCountSize, nil, 0)

        if pCount == 0 && eCount == 0 {
            pCount = numLogicalCPUs
        }
        pCoreCount = pCount
        eCoreCount = eCount

        // Bootstrap total memory
        var physMib = [CTL_HW, HW_MEMSIZE]
        var physBytes: UInt64 = 0
        var physSize = MemoryLayout<UInt64>.size
        sysctl(&physMib, 2, &physBytes, &physSize, nil, 0)
        memTotalGB = Double(physBytes) / 1_073_741_824.0

        // Pre-cache hardware registry descriptors for constant-time lookups (huge CPU saver)
        let gpuMatching = IOServiceMatching("IOAccelerator")
        var gpuIter: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, gpuMatching, &gpuIter) == KERN_SUCCESS {
            var service = IOIteratorNext(gpuIter)
            while service != 0 {
                cachedGPUServices.append(service)
                service = IOIteratorNext(gpuIter)
            }
            IOObjectRelease(gpuIter)
        }

        let diskMatching = IOServiceMatching("IOBlockStorageDriver")
        var diskIter: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, diskMatching, &diskIter) == KERN_SUCCESS {
            var service = IOIteratorNext(diskIter)
            while service != 0 {
                cachedDiskServices.append(service)
                service = IOIteratorNext(diskIter)
            }
            IOObjectRelease(diskIter)
        }
    }

    deinit {
        if let prev = prevCpuInfo {
            vm_deallocate(mach_task_self_,
                          vm_address_t(bitPattern: prev),
                          vm_size_t(Int(prevCpuInfoCount) * MemoryLayout<integer_t>.size))
        }
        for service in cachedGPUServices { IOObjectRelease(service) }
        for service in cachedDiskServices { IOObjectRelease(service) }
    }

    // MARK: - CPU
    struct CPUResult {
        var cores: [Double]; var total: Double; var user: Double; var system: Double
    }

    func collectCPU() -> CPUResult {
        var numProcs: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
                                     &numProcs, &infoArray, &infoCount)
        guard kr == KERN_SUCCESS, let newInfo = infoArray else {
            return CPUResult(cores: Array(repeating: 0, count: numLogicalCPUs), total: 0, user: 0, system: 0)
        }

        var cores = [Double](repeating: 0, count: Int(numProcs))
        var totalUser: Double = 0; var totalSys: Double = 0; var totalIdle: Double = 0

        if let prev = prevCpuInfo {
            for i in 0..<Int(numProcs) {
                let o = i * Int(CPU_STATE_MAX)
                let nUser = Int32(newInfo[o + Int(CPU_STATE_USER)])
                let nSys  = Int32(newInfo[o + Int(CPU_STATE_SYSTEM)])
                let nNice = Int32(newInfo[o + Int(CPU_STATE_NICE)])
                let nIdle = Int32(newInfo[o + Int(CPU_STATE_IDLE)])
                let pUser = Int32(prev[o + Int(CPU_STATE_USER)])
                let pSys  = Int32(prev[o + Int(CPU_STATE_SYSTEM)])
                let pNice = Int32(prev[o + Int(CPU_STATE_NICE)])
                let pIdle = Int32(prev[o + Int(CPU_STATE_IDLE)])

                let dActive = Double((nUser - pUser) + (nSys - pSys) + (nNice - pNice))
                let dIdle   = Double(max(0, nIdle - pIdle))
                let dTotal  = dActive + dIdle
                cores[i]    = dTotal > 0 ? max(0, min(1, dActive / dTotal)) : 0

                totalUser += Double(nUser - pUser)
                totalSys  += Double(nSys - pSys)
                totalIdle += dIdle
            }
        }

        // Free previous
        if let prev = prevCpuInfo {
            vm_deallocate(mach_task_self_,
                          vm_address_t(bitPattern: prev),
                          vm_size_t(Int(prevCpuInfoCount) * MemoryLayout<integer_t>.size))
        }
        prevCpuInfo = newInfo
        prevCpuInfoCount = infoCount

        let grandTotal = totalUser + totalSys + totalIdle
        let total  = grandTotal > 0 ? (totalUser + totalSys) / grandTotal : 0
        let user   = grandTotal > 0 ? totalUser / grandTotal : 0
        let system = grandTotal > 0 ? totalSys  / grandTotal : 0

        return CPUResult(cores: cores, total: total, user: user, system: system)
    }

    // MARK: - Memory
    struct MemResult { var used: Double; var pressure: Double; var cached: Double }

    func collectMemory() -> MemResult {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return MemResult(used: 0, pressure: 0, cached: 0) }

        let pageSize = Double(vm_kernel_page_size)
        let active   = Double(stats.active_count)   * pageSize
        let wired    = Double(stats.wire_count)      * pageSize
        let compress = Double(stats.compressor_page_count) * pageSize
        let inactive = Double(stats.inactive_count)  * pageSize
        let specul   = Double(stats.speculative_count) * pageSize

        let used     = (active + wired + compress) / 1_073_741_824.0
        let cached   = (inactive + specul) / 1_073_741_824.0
        let total    = memTotalGB > 0 ? memTotalGB : 1
        let pressure = min(1.0, max(0.0, used / total))

        return MemResult(used: used, pressure: pressure, cached: cached)
    }

    // MARK: - Network
    struct NetResult { var up: Double; var down: Double }

    func collectNetwork() -> NetResult {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0 else { return NetResult(up: 0, down: 0) }
        defer { freeifaddrs(ifaddrs) }

        var totalIn: UInt64 = 0; var totalOut: UInt64 = 0
        var cursor = ifaddrs

        while let ifa = cursor {
            if let data = ifa.pointee.ifa_data {
                let ifdata = data.assumingMemoryBound(to: if_data.self)
                let flags = Int32(ifa.pointee.ifa_flags)
                let isLoopback = (flags & IFF_LOOPBACK) != 0
                let isUp       = (flags & IFF_UP) != 0
                if isUp && !isLoopback {
                    totalIn  += UInt64(ifdata.pointee.ifi_ibytes)
                    totalOut += UInt64(ifdata.pointee.ifi_obytes)
                }
            }
            cursor = ifa.pointee.ifa_next
        }

        let now = ProcessInfo.processInfo.systemUptime
        let dt = prevNetUptime.map { max(0.1, now - $0) } ?? 0.1
        let downKBps = (prevNetDown > 0 && totalIn >= prevNetDown) ? Double(totalIn - prevNetDown) / dt / 1024.0 : 0
        let upKBps   = (prevNetUp > 0 && totalOut >= prevNetUp) ? Double(totalOut - prevNetUp) / dt / 1024.0 : 0
        prevNetDown = totalIn; prevNetUp = totalOut; prevNetUptime = now

        return NetResult(up: max(0, upKBps), down: max(0, downKBps))
    }

    // MARK: - Disk I/O
    struct DiskResult { var read: Double; var write: Double }

    func collectDisk() -> DiskResult {
        var totalRead: UInt64 = 0; var totalWrite: UInt64 = 0

        for service in cachedDiskServices {
            var props: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0)
            if let dict = props?.takeRetainedValue() as? [String: Any],
               let stats = dict["Statistics"] as? [String: Any] {
                let r = stats["Bytes (Read)"]  as? UInt64 ?? 0
                let w = stats["Bytes (Write)"] as? UInt64 ?? 0
                totalRead  += r
                totalWrite += w
            }
        }

        let now = ProcessInfo.processInfo.systemUptime
        let dt = prevDiskUptime.map { max(0.1, now - $0) } ?? 0.1
        let readMBps  = (prevDiskRead > 0 && totalRead >= prevDiskRead) ? Double(totalRead - prevDiskRead) / dt / 1_048_576.0 : 0
        let writeMBps = (prevDiskWrite > 0 && totalWrite >= prevDiskWrite) ? Double(totalWrite - prevDiskWrite) / dt / 1_048_576.0 : 0
        prevDiskRead = totalRead; prevDiskWrite = totalWrite; prevDiskUptime = now

        return DiskResult(read: max(0, readMBps), write: max(0, writeMBps))
    }

    // MARK: - GPU
    struct GPUResult { var utilization: Double; var memUsedBytes: UInt64 }

    func collectGPU() -> GPUResult {
        var util: Double = 0
        var memBytes: UInt64 = 0

        for service in cachedGPUServices {
            var props: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0)
            if let dict = props?.takeRetainedValue() as? [String: Any],
               let perfStats = dict["PerformanceStatistics"] as? [String: Any] {

                if let devR = perfStats["Device Utilization %"] as? Int {
                    util = Double(devR) / 100.0
                } else if let devD = perfStats["Device Utilization %"] as? Double {
                    util = devD / 100.0
                }

                if let mem = perfStats["In use system memory"] as? UInt64 {
                    memBytes = mem
                }
            }
        }
        return GPUResult(utilization: max(0, min(1, util)), memUsedBytes: memBytes)
    }

    func collectSnapshot() -> Snapshot {
        Snapshot(
            cpu: collectCPU(),
            memory: collectMemory(),
            network: collectNetwork(),
            disk: collectDisk(),
            gpu: collectGPU(),
            temperature: SMCService.shared.readFloat(key: "Tp09") ?? SMCService.shared.readFloat(key: "TC0P") ?? 0,
            sampledUptime: ProcessInfo.processInfo.systemUptime
        )
    }
}

import Foundation
import Combine
import Darwin

class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()

    // MARK: - CPU
    @Published var coreLoads: [Double] = []       // per-core 0.0~1.0
    @Published var pCoreCount: Int = 0
    @Published var eCoreCount: Int = 0
    @Published var cpuTotal: Double = 0.0         // average
    @Published var cpuUser: Double = 0.0
    @Published var cpuSystem: Double = 0.0
    @Published var cpuHistory: [Double] = Array(repeating: 0, count: 60)

    // MARK: - Memory
    @Published var memUsedGB: Double = 0.0
    @Published var memTotalGB: Double = 0.0
    @Published var memPressure: Double = 0.0      // 0.0~1.0
    @Published var memCachedGB: Double = 0.0
    @Published var memHistory: [Double] = Array(repeating: 0, count: 60)   // 0.0~1.0

    // MARK: - Network
    @Published var netUpKBps: Double = 0.0
    @Published var netDownKBps: Double = 0.0
    @Published var netDownHistory: [Double] = Array(repeating: 0, count: 60) // normalised 0~1
    @Published var netUpHistory:   [Double] = Array(repeating: 0, count: 60)

    // MARK: - Disk I/O
    @Published var diskReadMBps: Double = 0.0
    @Published var diskWriteMBps: Double = 0.0
    @Published var diskReadHistory:  [Double] = Array(repeating: 0, count: 60)
    @Published var diskWriteHistory: [Double] = Array(repeating: 0, count: 60)

    // MARK: - GPU
    @Published var gpuUtilization: Double = 0.0
    @Published var gpuHistory: [Double] = Array(repeating: 0, count: 60)
    @Published var gpuMemUsedGB: Double = 0.0
    @Published var gpuMemHistory: [Double] = Array(repeating: 0, count: 60)

    // MARK: - CPU Temperature (from SMCService)
    @Published var cpuTemperature: Double = 0.0

    // MARK: - History Peaks (rolling max for normalisation)
    private var netPeak:  Double = 1.0
    private var diskPeak: Double = 0.1

    // MARK: - Private State
    private var prevCpuInfo: processor_info_array_t?
    private var prevCpuInfoCount: mach_msg_type_number_t = 0
    private var prevNetDown: UInt64 = 0
    private var prevNetUp: UInt64 = 0
    private var prevDiskRead: UInt64 = 0
    private var prevDiskWrite: UInt64 = 0
    private var prevNetTimestamp: Date = .distantPast
    private var prevDiskTimestamp: Date = .distantPast

    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false

    private let numLogicalCPUs: Int

    init() {
        numLogicalCPUs = ProcessInfo.processInfo.processorCount
        coreLoads = Array(repeating: 0.0, count: numLogicalCPUs)
        
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

        // Tie into global tick
        EnergyEfficiencyManager.shared.tickPublisher
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    deinit {
        if let prev = prevCpuInfo {
            vm_deallocate(mach_task_self_,
                          vm_address_t(bitPattern: prev),
                          vm_size_t(Int(prevCpuInfoCount) * MemoryLayout<integer_t>.size))
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let cpu   = self.collectCPU()
            let mem   = self.collectMemory()
            let net   = self.collectNetwork()
            let disk  = self.collectDisk()
            let gpu   = self.collectGPU()
            let temp  = SMCService.shared.readFloat(key: "Tp09") ?? SMCService.shared.readFloat(key: "TC0P") ?? 0.0
            DispatchQueue.main.async {
                self.coreLoads  = cpu.cores
                self.cpuTotal   = cpu.total
                self.cpuUser    = cpu.user
                self.cpuSystem  = cpu.system
                self.memUsedGB  = mem.used
                self.memPressure = mem.pressure
                self.memCachedGB = mem.cached
                self.netUpKBps   = net.up
                self.netDownKBps = net.down
                self.diskReadMBps  = disk.read
                self.diskWriteMBps = disk.write
                self.cpuTemperature = temp
                self.gpuUtilization = gpu.utilization
                self.gpuMemUsedGB   = Double(gpu.memUsedBytes) / 1_073_741_824.0

                // --- History updates ---
                // CPU total history
                self.cpuHistory.removeFirst()
                self.cpuHistory.append(min(1, max(0, cpu.total)))

                // Memory pressure history
                self.memHistory.removeFirst()
                self.memHistory.append(min(1, max(0, mem.pressure)))

                // GPU history
                self.gpuHistory.removeFirst()
                self.gpuHistory.append(min(1, max(0, gpu.utilization)))

                // GPU VRAM history (ratio of total physical memory)
                self.gpuMemHistory.removeFirst()
                let gpuMemRatio = self.memTotalGB > 0 ? self.gpuMemUsedGB / self.memTotalGB : 0
                self.gpuMemHistory.append(min(1, max(0, gpuMemRatio)))

                // Network — rolling peak normalisation
                let maxNet = max(net.up, net.down, 1.0)
                self.netPeak = max(self.netPeak * 0.97, maxNet)   // slow decay
                self.netDownHistory.removeFirst()
                self.netDownHistory.append(min(1, net.down / self.netPeak))
                self.netUpHistory.removeFirst()
                self.netUpHistory.append(min(1, net.up / self.netPeak))

                // Disk — rolling peak normalisation
                let maxDisk = max(disk.read, disk.write, 0.01)
                self.diskPeak = max(self.diskPeak * 0.97, maxDisk)
                self.diskReadHistory.removeFirst()
                self.diskReadHistory.append(min(1, disk.read / self.diskPeak))
                self.diskWriteHistory.removeFirst()
                self.diskWriteHistory.append(min(1, disk.write / self.diskPeak))

                self.isRefreshing = false
            }
        }
    }

    // MARK: - CPU
    private struct CPUResult {
        var cores: [Double]; var total: Double; var user: Double; var system: Double
    }

    private func collectCPU() -> CPUResult {
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
    private struct MemResult { var used: Double; var pressure: Double; var cached: Double }

    private func collectMemory() -> MemResult {
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
    private struct NetResult { var up: Double; var down: Double }

    private func collectNetwork() -> NetResult {
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

        let now = Date()
        let dt  = max(0.1, now.timeIntervalSince(prevNetTimestamp))
        let downKBps = prevNetDown  > 0 ? Double(totalIn  - prevNetDown)  / dt / 1024.0 : 0
        let upKBps   = prevNetUp    > 0 ? Double(totalOut - prevNetUp)    / dt / 1024.0 : 0
        prevNetDown = totalIn; prevNetUp = totalOut; prevNetTimestamp = now

        return NetResult(up: max(0, upKBps), down: max(0, downKBps))
    }

    // MARK: - Disk I/O
    private struct DiskResult { var read: Double; var write: Double }

    private func collectDisk() -> DiskResult {
        let matching = IOServiceMatching("IOBlockStorageDriver")
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else {
            return DiskResult(read: 0, write: 0)
        }
        defer { IOObjectRelease(iter) }

        var totalRead: UInt64 = 0; var totalWrite: UInt64 = 0
        var service = IOIteratorNext(iter)
        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iter) }

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

        let now = Date()
        let dt  = max(0.1, now.timeIntervalSince(prevDiskTimestamp))
        let readMBps  = prevDiskRead  > 0 ? Double(totalRead  - prevDiskRead)  / dt / 1_048_576.0 : 0
        let writeMBps = prevDiskWrite > 0 ? Double(totalWrite - prevDiskWrite) / dt / 1_048_576.0 : 0
        prevDiskRead = totalRead; prevDiskWrite = totalWrite; prevDiskTimestamp = now

        return DiskResult(read: max(0, readMBps), write: max(0, writeMBps))
    }

    // MARK: - GPU
    private struct GPUResult { var utilization: Double; var memUsedBytes: UInt64 }

    private func collectGPU() -> GPUResult {
        let matching = IOServiceMatching("IOAccelerator")
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else {
            return GPUResult(utilization: 0, memUsedBytes: 0)
        }
        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        var util: Double = 0
        var memBytes: UInt64 = 0

        while service != 0 {
            defer { IOObjectRelease(service); service = IOIteratorNext(iter) }
            
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
}

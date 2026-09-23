import Foundation
import Combine
import Darwin

@MainActor
final class SystemMonitorService: ObservableObject {
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
    @Published var memPressure: Double = 0.0      // Used / total, not macOS memory pressure
    @Published var memCachedGB: Double = 0.0
    @Published var memHistory: [Double] = Array(repeating: 0, count: 60)   // 0.0~1.0

    // MARK: - Network
    @Published var netUpKBps: Double = 0.0
    @Published var netDownKBps: Double = 0.0
    @Published var netDownHistory: [Double] = Array(repeating: 0, count: 60) // raw KB/s; the view applies one scale to the entire window
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

    private var lastSampledUptime: TimeInterval?

    private let collector = SystemMetricsCollector()
    private let worker = DispatchQueue(label: "MacStatus.system-metrics", qos: .utility)
    private var isRefreshing = false

    private init() {
        pCoreCount = collector.pCoreCount
        eCoreCount = collector.eCoreCount
        memTotalGB = collector.memTotalGB
    }

    func sample(for policy: SamplingPolicy) async -> PowerBreakdownMetrics? {
        guard policy.needsSystemMetrics, !isRefreshing else {
            return policy.needsBreakdown ? currentBreakdownMetrics() : nil
        }
        isRefreshing = true
        let collector = self.collector
        let sample = await withCheckedContinuation { continuation in
            worker.async {
                continuation.resume(returning: collector.collectSnapshot())
            }
        }
        isRefreshing = false
        guard EnergyEfficiencyManager.shared.policy.needsSystemMetrics else { return nil }

        let cpu = sample.cpu
        let mem = sample.memory
        let net = sample.network
        let disk = sample.disk
        let gpu = sample.gpu
        coreLoads = cpu.cores
        cpuTotal = cpu.total
        cpuUser = cpu.user
        cpuSystem = cpu.system
        memUsedGB = mem.used
        memPressure = mem.pressure
        memCachedGB = mem.cached
        netUpKBps = net.up
        netDownKBps = net.down
        diskReadMBps = disk.read
        diskWriteMBps = disk.write
        cpuTemperature = sample.temperature
        gpuUtilization = gpu.utilization
        gpuMemUsedGB = Double(gpu.memUsedBytes) / 1_073_741_824.0
        lastSampledUptime = sample.sampledUptime

        cpuHistory.removeFirst()
        cpuHistory.append(min(1, max(0, cpu.total)))

        memHistory.removeFirst()
        memHistory.append(min(1, max(0, mem.pressure)))

        gpuHistory.removeFirst()
        gpuHistory.append(min(1, max(0, gpu.utilization)))

        gpuMemHistory.removeFirst()
        let gpuMemRatio = memTotalGB > 0 ? gpuMemUsedGB / memTotalGB : 0
        gpuMemHistory.append(min(1, max(0, gpuMemRatio)))

        netDownHistory.removeFirst()
        netDownHistory.append(max(0, net.down))
        netUpHistory.removeFirst()
        netUpHistory.append(max(0, net.up))
        diskReadHistory.removeFirst()
        diskReadHistory.append(max(0, disk.read))
        diskWriteHistory.removeFirst()
        diskWriteHistory.append(max(0, disk.write))

        return policy.needsBreakdown ? PowerBreakdownMetrics(
            cpuTotal: cpu.total,
            gpuUtilization: gpu.utilization,
            coreCount: pCoreCount + eCoreCount,
            sampledUptime: sample.sampledUptime
        ) : nil
    }

    private func currentBreakdownMetrics() -> PowerBreakdownMetrics {
        PowerBreakdownMetrics(
            cpuTotal: cpuTotal,
            gpuUtilization: gpuUtilization,
            coreCount: pCoreCount + eCoreCount,
            sampledUptime: lastSampledUptime ?? 0
        )
    }
}

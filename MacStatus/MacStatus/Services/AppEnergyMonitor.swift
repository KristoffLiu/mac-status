import AppKit
import Combine

@MainActor
final class AppEnergyMonitor: ObservableObject {
    static let shared = AppEnergyMonitor()
    @Published private(set) var topApp: TopAppUsage?
    private var cancellables = Set<AnyCancellable>()
    private let runner = CommandRunner()
    private var task: Task<String?, Never>?
    private var generation = UUID()
    private var refreshThrottle = MonotonicThrottle()

    private init() {
        let manager = EnergyEfficiencyManager.shared
        manager.$policy.sink { [weak self] policy in
            if !policy.needsBreakdown { self?.stop() }
        }.store(in: &cancellables)
    }

    private func stop() {
        generation = UUID()
        task?.cancel()
        task = nil
        topApp = nil
        refreshThrottle = MonotonicThrottle()
    }

    func sample(for policy: SamplingPolicy) async -> TopAppUsage? {
        guard policy.needsBreakdown else { return nil }
        guard task == nil else { return topApp }
        let now = ProcessInfo.processInfo.systemUptime
        guard refreshThrottle.shouldRun(now: now, minimumInterval: policy.appInterval) else { return topApp }
        let token = UUID()
        generation = token
        let command = Task { [runner] in
            await runner.run(executable: "/bin/ps", arguments: ["-A", "-o", "pid=,pcpu=,comm=", "-r"])
        }
        task = command
        let output = await command.value
        task = nil
        guard !Task.isCancelled, generation == token,
              EnergyEfficiencyManager.shared.policy.needsBreakdown else { return nil }
        let excluded = ["kernel_task", "WindowServer", "coreaudiod", "MacStatus", "ps"]
        let best = output.flatMap { output in
            ProcessOutputParser.cpu(output).first { row in
                row.value > 5 && row.pid != ProcessInfo.processInfo.processIdentifier && !excluded.contains((row.name as NSString).lastPathComponent)
            }
        }
        topApp = best.map { row in
            TopAppUsage(name: NSRunningApplication(processIdentifier: row.pid)?.localizedName ?? (row.name as NSString).lastPathComponent, cpuPercent: row.value)
        }
        return topApp
    }
}

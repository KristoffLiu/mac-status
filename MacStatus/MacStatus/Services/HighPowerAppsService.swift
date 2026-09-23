import AppKit
import Combine

struct AppEnergyImpact: Identifiable {
    var id: Int32 { pid }
    let pid: Int32
    let name: String
    let power: Double
    let icon: NSImage?
}

@MainActor
final class HighPowerAppsService: ObservableObject {
    static let shared = HighPowerAppsService()
    @Published private(set) var highPowerApps: [AppEnergyImpact] = []
    @Published private(set) var unavailable = false
    @Published private(set) var hasSample = false
    private var cancellables = Set<AnyCancellable>()
    private let runner = CommandRunner()
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private var refreshThrottle = MonotonicThrottle()

    private init() {
        let manager = EnergyEfficiencyManager.shared
        manager.$policy.sink { [weak self] policy in
            if !policy.needsHighPowerApps { self?.stop() }
        }.store(in: &cancellables)
    }

    private func stop() {
        generation = UUID()
        task?.cancel()
        task = nil
        highPowerApps = []
        hasSample = false
        unavailable = false
        refreshThrottle = MonotonicThrottle()
    }

    func refresh(for policy: SamplingPolicy) {
        guard policy.needsHighPowerApps, task == nil,
              refreshThrottle.shouldRun(now: ProcessInfo.processInfo.systemUptime, minimumInterval: 8) else { return }
        let token = UUID()
        generation = token
        task = Task { [weak self, runner] in
            let output = await runner.run(executable: "/usr/bin/top", arguments: ["-l", "2", "-stats", "pid,command,power", "-o", "power", "-n", "10"])
            guard let self, !Task.isCancelled, generation == token else { return }
            defer { task = nil }
            hasSample = true
            guard let output, let rows = ProcessOutputParser.energy(output) else {
                unavailable = true
                highPowerApps = []
                return
            }
            unavailable = false
            highPowerApps = Array(rows.filter { row in
                row.value > 1 && !["WindowServer", "kernel_task", "launchd", "MacStatus", "top"].contains(row.name)
            }.compactMap { row -> AppEnergyImpact? in
                guard let app = NSRunningApplication(processIdentifier: row.pid) else { return nil }
                return AppEnergyImpact(pid: row.pid, name: app.localizedName ?? row.name, power: row.value, icon: app.icon)
            }.prefix(3))
        }
    }
}

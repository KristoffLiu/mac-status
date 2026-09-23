import Foundation

/// Owns the one-tick acquisition sequence and hands calculation one coherent value snapshot.
@MainActor
final class StatusSnapshotCoordinator {
    static let shared = StatusSnapshotCoordinator()

    private let powerAdapter: any PowerSampleAdapter

    init(powerAdapter: any PowerSampleAdapter = PowerSampler.shared) {
        self.powerAdapter = powerAdapter
    }

    func sample(for policy: SamplingPolicy) async -> StatusSnapshot {
        HighPowerAppsService.shared.refresh(for: policy)

        async let power = powerAdapter.sample()
        async let breakdown = SystemMonitorService.shared.sample(for: policy)
        async let topApp = AppEnergyMonitor.shared.sample(for: policy)
        let values = await (power, breakdown, topApp)

        return StatusSnapshot(
            power: values.0,
            breakdown: values.1,
            topApp: values.2,
            sampledUptime: ProcessInfo.processInfo.systemUptime
        )
    }
}

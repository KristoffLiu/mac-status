import Foundation

nonisolated struct PowerSample: Sendable {
    var battery: BatteryData
    var sensors: PowerSensors
}

nonisolated protocol PowerSampleAdapter: Sendable {
    func sample() async -> PowerSample
}

/// A deterministic adapter for replaying captured hardware samples in tests and diagnostics.
nonisolated actor RecordedPowerSampleAdapter: PowerSampleAdapter {
    private let samples: [PowerSample]
    private var index = 0

    init(samples: [PowerSample]) {
        precondition(!samples.isEmpty, "RecordedPowerSampleAdapter requires at least one sample")
        self.samples = samples
    }

    func sample() -> PowerSample {
        let result = samples[min(index, samples.count - 1)]
        index += 1
        return result
    }
}

nonisolated struct PowerBreakdownMetrics: Sendable, Equatable {
    var cpuTotal: Double
    var gpuUtilization: Double
    var coreCount: Int
    var sampledUptime: TimeInterval
}

/// The coherent value passed from acquisition to calculation for one application tick.
nonisolated struct StatusSnapshot: Sendable {
    var battery: BatteryData
    var sensors: PowerSensors
    var sampledUptime: TimeInterval
    var breakdownSampledUptime: TimeInterval?

    init(
        power: PowerSample,
        breakdown: PowerBreakdownMetrics?,
        topApp: TopAppUsage?,
        sampledUptime: TimeInterval
    ) {
        battery = power.battery
        sensors = power.sensors
        self.sampledUptime = sampledUptime
        breakdownSampledUptime = breakdown?.sampledUptime
        if let breakdown {
            sensors.cpuTotal = breakdown.cpuTotal
            sensors.gpuUtilization = breakdown.gpuUtilization
            sensors.coreCount = breakdown.coreCount
            sensors.topApp = topApp
            sensors.includeBreakdown = true
        }
    }
}

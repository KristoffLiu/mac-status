import Foundation

nonisolated enum PowerSource: Sendable { case ac, battery, unknown }
nonisolated struct TopAppUsage: Sendable {
    var name: String
    var cpuPercent: Double
}

/// A value snapshot: calculation never reads hardware or another module's mutable state.
nonisolated struct PowerSensors: Sendable {
    var source: PowerSource = .unknown
    var systemWatts: Double?
    var adapterVoltage: Double?
    var adapterCurrent: Double?
    var cpuTotal: Double = 0
    var gpuUtilization: Double = 0
    var coreCount: Int = 0
    var topApp: TopAppUsage?
    var includeBreakdown: Bool = false
}

import Foundation

nonisolated enum TopologyState: Sendable, Equatable {
    case topologyA // Surplus: Adapter -> Battery & System
    case topologyB // Deficit/Battery: Adapter + Battery -> System, or Battery -> System
}

/// Stable UI interpretation of battery activity. It does not replace the raw power reading.
nonisolated enum BatteryActivityState: Sendable, Equatable {
    case unavailable
    case confirming
    case lowActivity
    case idle
    case charging
    case assisting
    case batteryPowered
}

nonisolated struct PowerFlowData: Sendable, Equatable {
    var adapterPower: Double // W
    var batteryPower: Double // W (Absolute value)
    var systemPower: Double // W
    
    var isCharging: Bool // True if battery is charging
    var isDischarging: Bool // True if battery is discharging (amperage < 0)
    
    var topology: TopologyState
    var adapterVoltage: Double?
    var adapterCurrent: Double?
    
    var adapterQuality: ReadingQuality = .measured
    var batteryQuality: ReadingQuality = .measured
    var systemQuality: ReadingQuality = .measured
    var externalPowerConnected: Bool?
    var readingsConflict = false
    /// Adapter input and system load are valid but not directly comparable on this Mac.
    var powerDomainsDiffer = false
    var signedBatteryPower: Double? = nil
    var batteryActivity: BatteryActivityState = .unavailable
    var batteryTrend: BatteryPowerTrend = .empty

    /// Battery power that is safe to draw as a directed flow.
    var directionalBatteryPower: Double {
        switch batteryActivity {
        case .charging, .assisting, .batteryPowered: batteryPower
        default: 0
        }
    }

    /// Power used by the diagram's adapter branch. Raw adapter input remains in adapterPower.
    /// This keeps the flow balanced when adapter and system sensors cover different domains.
    var adapterSupplyPower: Double {
        guard hasAdapter else { return 0 }
        guard systemQuality != .unavailable else { return adapterPower }
        if isCharging { return systemPower + directionalBatteryPower }
        if isDischarging { return max(0, systemPower - directionalBatteryPower) }
        return systemPower
    }

    var hasAdapter: Bool { externalPowerConnected ?? (adapterPower > 0) }
    var isComplete: Bool {
        !readingsConflict && adapterQuality != .unavailable && batteryQuality != .unavailable && systemQuality != .unavailable
    }
    var hasEstimates: Bool {
        adapterQuality == .estimated || batteryQuality == .estimated || systemQuality == .estimated
    }

    // Three-Stage Output Breakdown
    var coreWatts: Double? = nil
    var peripheralWatts: Double? = nil
    var topAppWatts: Double? = nil
    var topAppName: String? = nil
}

nonisolated enum ReadingQuality: Sendable, Equatable {
    case measured, estimated, unavailable

    func format(_ watts: Double) -> String {
        guard self != .unavailable, watts.isFinite else { return "—" }
        return (self == .estimated ? "≈" : "") + String(format: "%.1f W", watts)
    }
}

import Foundation

enum TopologyState {
    case topologyA // Surplus: Adapter -> Battery & System
    case topologyB // Deficit/Battery: Adapter + Battery -> System, or Battery -> System
}

struct PowerFlowData {
    var adapterPower: Double // W
    var batteryPower: Double // W (Absolute value)
    var systemPower: Double // W
    
    var isCharging: Bool // True if battery is charging
    var isDischarging: Bool // True if battery is discharging (amperage < 0)
    
    var topology: TopologyState
    var adapterVoltage: Double?
    var adapterCurrent: Double?
    
    // Three-Stage Output Breakdown
    var coreWatts: Double? = nil
    var peripheralWatts: Double? = nil
    var topAppWatts: Double? = nil
    var topAppName: String? = nil
}

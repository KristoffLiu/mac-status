import Foundation

class PowerCalculationService {
    static let shared = PowerCalculationService()
    
    private init() {}
    
    func calculateFlow(from data: BatteryData) -> PowerFlowData {
        let adapterWatts = Double(data.adapterWatts)
        let batteryWatts = abs(Double(data.voltage) / 1000.0 * Double(data.amperage) / 1000.0)
        
        var systemWatts: Double = 0.0
        var topology: TopologyState = .topologyB
        var isCharging = false
        var isDischarging = false
        
        if data.amperage > 0 {
            // Charging
            isCharging = true
            isDischarging = false
            // We know what goes into the battery, but without SMC, total system power is unknown.
            // We use -1.0 to represent "Unknown" in the UI.
            systemWatts = -1.0
            topology = .topologyA
        } else if data.amperage < 0 {
            // Discharging
            isCharging = false
            isDischarging = true
            // If we are discharging, the battery power is entirely consumed by the system.
            systemWatts = batteryWatts
            topology = .topologyB
        } else {
            // Idle / Bypass (Fully charged and connected to AC)
            isCharging = false
            isDischarging = false
            if adapterWatts > 0 {
                // Adapter bypass
                systemWatts = -1.0 // Unknown AC draw without SMC
                topology = .topologyA
            } else {
                // Unknown / no load
                systemWatts = 0.0
                topology = .topologyB
            }
        }
        
        return PowerFlowData(
            adapterPower: adapterWatts,
            batteryPower: batteryWatts,
            systemPower: systemWatts,
            isCharging: isCharging,
            isDischarging: isDischarging,
            topology: topology
        )
    }
}

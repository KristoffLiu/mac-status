import Foundation

class PowerCalculationService {
    static let shared = PowerCalculationService()
    
    private init() {}
    
    func calculateFlow(from data: BatteryData, mSeriesMetrics: MSeriesPowerMetrics? = nil) -> PowerFlowData {
        // Use real-time PMU intake if available, fallback to design rating
        let adapterWatts = data.adapter?.realTimeWatts ?? Double(data.adapterWatts)
        let batteryWatts = abs(Double(data.voltage) / 1000.0 * Double(data.amperage) / 1000.0)
        
        var systemWatts: Double = 0.0
        var topology: TopologyState = .topologyB
        var isCharging = false
        var isDischarging = false
        
        if data.amperage > 0 {
            // Charging
            isCharging = true
            isDischarging = false
            // Use total adapter intake minus battery charge rate to get actual system usage
            systemWatts = adapterWatts - batteryWatts
            topology = .topologyA
        } else if data.amperage < 0 {
            // Discharging
            isCharging = false
            isDischarging = true
            // In discharge, the system draw is the battery power (IOKit is accurate here)
            // But we can cross-reference with M-series metrics for higher precision
            systemWatts = mSeriesMetrics?.totalSystemWatts ?? batteryWatts
            topology = .topologyB
        } else {
            // Idle / Bypass (Fully charged and connected to AC)
            isCharging = false
            isDischarging = false
            if adapterWatts > 0 {
                // Adapter bypass
                // True system draw is exactly the real-time intake from the adapter
                systemWatts = adapterWatts
                topology = .topologyA
            } else {
                // Unknown / no load
                systemWatts = mSeriesMetrics?.totalSystemWatts ?? 0.0
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

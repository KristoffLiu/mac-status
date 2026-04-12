import Foundation
import IOKit.ps

class PowerCalculationService {
    static let shared = PowerCalculationService()
    
    private init() {}
    
    func calculateFlow(from data: BatteryData) -> PowerFlowData {
        // High-Fidelity Power Fetching via AppleSMC
        // 'PSTR' gets the true total system draw in real-time
        let smcSystemWatts = SMCService.shared.systemTotalPower
        
        let powerSourceType = IOPSGetProvidingPowerSourceType(nil)?.takeRetainedValue() as? String ?? ""
        let isTrueAC = (powerSourceType == "AC Power")
        
        // IOKit caches AppleSmartBattery data for seconds. Force adapter to 0 if the system physically switched to battery!
        let adapterWatts = isTrueAC ? (data.adapter?.realTimeWatts ?? Double(data.adapterWatts)) : 0.0
        
        let batteryWatts = abs(Double(data.voltage) / 1000.0 * Double(data.amperage) / 1000.0)

        
        var systemWatts: Double = 0.0
        var topology: TopologyState = .topologyB
        var isCharging = false
        var isDischarging = false
        
        if data.amperage > 0 {
            // Charging
            isCharging = true
            isDischarging = false
            // Real-time system power is preferred, otherwise fallback to adapter - battery
            systemWatts = smcSystemWatts ?? (adapterWatts - batteryWatts)
            topology = .topologyA
        } else if data.amperage < 0 {
            // Discharging
            isCharging = false
            isDischarging = true
            // In discharge, the system draw is the battery power, but SMC 'PSTR' is even more accurate
            systemWatts = smcSystemWatts ?? batteryWatts
            topology = .topologyB
        } else {
            // Idle / Bypass (Fully charged and connected to AC)
            isCharging = false
            isDischarging = false
            
            // In bypass, the total system power comes entirely from the adapter.
            // PSTR tells us exactly what the system is drawing right now.
            if let smcWatts = smcSystemWatts {
                systemWatts = smcWatts
                topology = .topologyA
            } else if adapterWatts > 0 {
                // Fallback
                systemWatts = adapterWatts
                topology = .topologyA
            } else {
                // Unknown / no load
                systemWatts = 0.0
                topology = .topologyB
            }
        }
        
        // For the visual flow logic (adapterPower rendering)
        // If systemWatts > 0 and we are in bypass, true adapter intake is systemWatts + batteryWatts.
        var trueAdapterWatts = adapterWatts
        if isCharging {
            trueAdapterWatts = systemWatts + batteryWatts
        } else if !isDischarging && topology == .topologyA {
            trueAdapterWatts = systemWatts
        } else if isDischarging {
            // When discharging, the adapter might be assisting (rare but possible under heavy load).
            // Trust the real-time intake watts from the PMU if present.
            // Ensure if we are physically unplugged (adapter == nil), it stays at 0.
            if data.adapter == nil {
                trueAdapterWatts = 0.0
            } else {
                trueAdapterWatts = adapterWatts
            }
        }
        
        return PowerFlowData(
            adapterPower: trueAdapterWatts,
            batteryPower: batteryWatts,
            systemPower: systemWatts,
            isCharging: isCharging,
            isDischarging: isDischarging,
            topology: topology
        )
    }
}

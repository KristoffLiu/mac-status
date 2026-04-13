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
        let isTrueAC = (powerSourceType == "AC Power") || (data.adapter != nil) || (data.adapterWatts > 0)
        
        // IOKit caches AppleSmartBattery data for seconds. Force adapter to 0 if the system physically switched to battery!
        let adapterWatts = isTrueAC ? (data.adapter?.realTimeWatts ?? Double(data.adapterWatts)) : 0.0
        
        // Some adapters don't broadcast real-time watts via BatteryData dict, so if it's 0 but it's connected, fallback to design watts or smc.
        let actualAdapterWatts = (adapterWatts <= 0.1 && isTrueAC) ? Double(data.adapterWatts) : adapterWatts
        
        var batteryWatts = abs(Double(data.voltage) / 1000.0 * Double(data.amperage) / 1000.0)

        
        var systemWatts: Double = 0.0
        var topology: TopologyState = .topologyB
        var isCharging = false
        var isDischarging = false
        
        let actualAmperage = data.amperage
        
        if !isTrueAC {
            // Physically unplugged. Override stale battery data.
            isCharging = false
            isDischarging = true
            // If SMC system watts is there, use it as battery watts; else estimate
            systemWatts = smcSystemWatts ?? batteryWatts
            topology = .topologyB
        } else if actualAmperage > 0 {
            // Charging
            isCharging = true
            isDischarging = false
            // Real-time system power is preferred, otherwise fallback to adapter - battery
            systemWatts = smcSystemWatts ?? (actualAdapterWatts - batteryWatts)
            topology = .topologyA
        } else if actualAmperage < 0 {
            // Discharging...
            // BUT wait! If we are plugged in (isTrueAC), and the adapter is clearly strong enough 
            // to power the system (adapterWatts >= system draw), then the battery is idling!
            // IOKit's battery controller is merely lagging behind the AC controller. We shouldn't show a frozen "discharging ghost".
            let currentSystemDraw = smcSystemWatts ?? actualAdapterWatts
            let theoreticalTotalSource = actualAdapterWatts + batteryWatts
            
            // If the battery alone claims to be discharging roughly as much (or more) than the whole system is drawing,
            // while we are physically on AC power, it's definitively a lagging ghost sensor.
            let isDefinitivelyLagging = (smcSystemWatts != nil && batteryWatts >= currentSystemDraw * 0.7)
            
            let isGhost = isTrueAC && (
                isDefinitivelyLagging ||
                actualAdapterWatts >= currentSystemDraw * 0.6 ||
                (smcSystemWatts != nil && theoreticalTotalSource > currentSystemDraw + 15.0)
            )
            
            if isGhost || (isTrueAC && actualAdapterWatts > currentSystemDraw) {
                // False negative: It's just transient lag. Force bypass/charging state logic.
                isCharging = false
                isDischarging = false
                systemWatts = smcSystemWatts ?? actualAdapterWatts
                batteryWatts = 0.0 // 🛑 CRITICAL FIX: Kill the ghost battery value
                topology = .topologyA
            } else {
                // Genuinely discharging alongside adapter (or unplugged)
                isCharging = false
                isDischarging = true
                systemWatts = smcSystemWatts ?? batteryWatts
                topology = .topologyB
            }
        } else {
            // Idle / Bypass (Fully charged and connected to AC)
            isCharging = false
            isDischarging = false
            
            // In bypass, the total system power comes entirely from the adapter.
            // PSTR tells us exactly what the system is drawing right now.
            if let smcWatts = smcSystemWatts {
                systemWatts = smcWatts
                topology = .topologyA
            } else if actualAdapterWatts > 0 {
                // Fallback
                systemWatts = actualAdapterWatts
                topology = .topologyA
            } else {
                // Unknown / no load
                systemWatts = 0.0
                topology = .topologyB
            }
        }
        
        // For the visual flow logic (adapterPower rendering)
        // If systemWatts > 0 and we are in bypass, trueAdapterWatts is systemWatts + batteryWatts.
        // NEW: Fetch real-time high-fidelity hardware adapter sensors if available
        let smcAdapterVolts = SMCService.shared.adapterVoltage
        let smcAdapterAmps = SMCService.shared.adapterCurrent
        
        var smcAdapterWatts: Double? = nil
        if let v = smcAdapterVolts, let a = smcAdapterAmps, v > 0, a > 0 {
            smcAdapterWatts = v * a
        }

        var trueAdapterWatts = actualAdapterWatts
        if isCharging {
            if let realAdapter = smcAdapterWatts, let realSystem = smcSystemWatts {
                batteryWatts = max(0.0, realAdapter - realSystem)
                trueAdapterWatts = realAdapter
            } else {
                trueAdapterWatts = systemWatts + batteryWatts
            }
        } else if !isDischarging && topology == .topologyA {
            trueAdapterWatts = smcAdapterWatts ?? systemWatts
        } else if isDischarging {
            // When discharging, the adapter might be assisting (rare but possible under heavy load).
            // Trust the real-time intake watts from the PMU if present.
            // Ensure if we are physically unplugged (adapter == nil or !isTrueAC), it stays at 0.
            if data.adapter == nil || !isTrueAC {
                trueAdapterWatts = 0.0
            } else {
                trueAdapterWatts = smcAdapterWatts ?? actualAdapterWatts
            }
        }
        

        
        return PowerFlowData(
            adapterPower: trueAdapterWatts,
            batteryPower: batteryWatts,
            systemPower: systemWatts,
            isCharging: isCharging,
            isDischarging: isDischarging,
            topology: topology,
            adapterVoltage: smcAdapterVolts,
            adapterCurrent: smcAdapterAmps
        )
    }
}

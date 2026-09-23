import Foundation
import IOKit
import IOKit.ps

nonisolated final class BatteryService: Sendable {
    static let shared = BatteryService()
    
    private init() {}
    
    func fetchBatteryData() -> BatteryData {
        var data = BatteryData.empty
        
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                if let dict = properties?.takeRetainedValue() as? [String: Any] {
                    data.isAvailable = true
                    data.sampledAt = Date()
                    data.externalConnected = dict["ExternalConnected"] as? Bool
                    data.currentCapacityMAh = dict["AppleRawCurrentCapacity"] as? Int
                    data.hasCurrentReading = dict["InstantAmperage"] != nil || dict["Amperage"] != nil
                    data.voltage = dict["Voltage"] as? Int ?? 0
                    
                    let instantAmperage = dict["InstantAmperage"] as? Int
                    let standardAmperage = dict["Amperage"] as? Int ?? 0
                    data.amperage = instantAmperage ?? standardAmperage
                    
                    data.isCharging = dict["IsCharging"] as? Bool ?? false
                    data.currentCapacity = min(100, max(0, dict["CurrentCapacity"] as? Int ?? 0))
                    
                    // For Apple Silicon, MaxCapacity is just 100%, we need AppleRawMaxCapacity
                    let rawMax = dict["AppleRawMaxCapacity"] as? Int ?? 0
                    let standardMax = dict["MaxCapacity"] as? Int ?? 0
                    data.maxCapacity = rawMax > 100 ? rawMax : (standardMax > 100 ? standardMax : 0)
                    
                    data.appleRawMaxCapacity = rawMax > 0 ? rawMax : nil
                    data.appleMaxCapacity = standardMax > 0 ? standardMax : nil
                    
                    if let time = dict["TimeRemaining"] as? Int, time > 0, time < 65535 {
                        data.timeRemaining = time
                    }
                    
                    data.designCapacity = dict["DesignCapacity"] as? Int ?? 0
                    data.cycleCount = dict["CycleCount"] as? Int ?? 0
                    
                    let rawTemp = dict["Temperature"] as? Int ?? 0
                    data.temperature = Double(rawTemp) / 100.0
                    
                    // Parse Real-time Adapter Power from internal BatteryData dict
                    var realTimeIntake: Double?
                    if let internalBatteryData = dict["BatteryData"] as? [String: Any],
                       let adapterPower = internalBatteryData["AdapterPower"] as? NSNumber {
                        realTimeIntake = adapterPower.doubleValue
                    }
                    
                    // Parse Adapter Details & PD Profiles
                    let isExternalConnected = dict["ExternalConnected"] as? Bool ?? false
                    
                    if isExternalConnected, let adapterDetails = dict["AdapterDetails"] as? [String: Any] {
                        data.adapterWatts = adapterDetails["Watts"] as? Int ?? 0
                        
                        var profiles: [PDProfile] = []
                        if let hvcMenu = adapterDetails["UsbHvcMenu"] as? [[String: Any]] {
                            for profile in hvcMenu {
                                let index = profile["Index"] as? Int ?? 0
                                let maxV = Double(profile["MaxVoltage"] as? Int ?? 0) / 1000.0
                                let maxC = Double(profile["MaxCurrent"] as? Int ?? 0) / 1000.0
                                profiles.append(PDProfile(index: index, maxVoltage: maxV, maxCurrent: maxC))
                            }
                        }
                        
                        let currentAdapterVoltage = Double(adapterDetails["Voltage"] as? Int ?? 0) / 1000.0
                        let currentAdapterCurrent = Double(adapterDetails["Current"] as? Int ?? 0) / 1000.0
                        
                        data.adapter = AdapterInfo(
                            id: adapterDetails["AdapterID"] as? Int ?? 0,
                            familyCode: adapterDetails["FamilyCode"] as? Int ?? 0,
                            name: adapterDetails["Name"] as? String ?? adapterDetails["Description"] as? String ?? "Unknown",
                            manufacturer: adapterDetails["Manufacturer"] as? String,
                            designWatts: data.adapterWatts,
                            realTimeWatts: realTimeIntake ?? 0,
                            activeProfileIndex: adapterDetails["UsbHvcHvcIndex"] as? Int ?? 0,
                            profiles: profiles,
                            current: currentAdapterCurrent,
                            voltage: currentAdapterVoltage,
                            watts: Double(data.adapterWatts)
                        )
                        data.adapter?.hasRealTimePower = realTimeIntake != nil
                    } else {
                        data.adapterWatts = 0
                    }
                }
            }
            IOObjectRelease(service)
        }
        
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                      description["Type"] as? String == "InternalBattery" else { continue }
                if let health = description["BatteryHealth"] as? String {
                    data.condition = health == "Good" ? String(localized: "正常") : health
                }
            }
        }
        return data
    }
}

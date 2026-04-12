import Foundation
import IOKit

struct BatteryData {
    var voltage: Int
    var amperage: Int
    var isCharging: Bool
    var currentCapacity: Int
    var maxCapacity: Int
    var designCapacity: Int
    var cycleCount: Int
    var temperature: Double
    var adapterWatts: Int
    
    static let empty = BatteryData(voltage: 0, amperage: 0, isCharging: false, currentCapacity: 0, maxCapacity: 0, designCapacity: 0, cycleCount: 0, temperature: 0.0, adapterWatts: 0)
}

class BatteryService {
    static let shared = BatteryService()
    
    private init() {}
    
    func fetchBatteryData() -> BatteryData {
        var data = BatteryData.empty
        
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                if let dict = properties?.takeRetainedValue() as? [String: Any] {
                    data.voltage = dict["Voltage"] as? Int ?? 0
                    
                    let instantAmperage = dict["InstantAmperage"] as? Int ?? 0
                    let standardAmperage = dict["Amperage"] as? Int ?? 0
                    data.amperage = instantAmperage != 0 ? instantAmperage : standardAmperage
                    
                    data.isCharging = dict["IsCharging"] as? Bool ?? false
                    data.currentCapacity = dict["CurrentCapacity"] as? Int ?? 0
                    
                    // For Apple Silicon, MaxCapacity is just 100%, we need AppleRawMaxCapacity
                    let rawMax = dict["AppleRawMaxCapacity"] as? Int ?? 0
                    let standardMax = dict["MaxCapacity"] as? Int ?? 0
                    data.maxCapacity = rawMax > 100 ? rawMax : standardMax
                    
                    data.designCapacity = dict["DesignCapacity"] as? Int ?? 0
                    data.cycleCount = dict["CycleCount"] as? Int ?? 0
                    
                    let rawTemp = dict["Temperature"] as? Int ?? 0
                    data.temperature = Double(rawTemp) / 100.0
                    
                    if let adapterDetails = dict["AdapterDetails"] as? [String: Any] {
                        data.adapterWatts = adapterDetails["Watts"] as? Int ?? 0
                    } else {
                        data.adapterWatts = 0
                    }
                }
            }
            IOObjectRelease(service)
        }
        
        return data
    }
}

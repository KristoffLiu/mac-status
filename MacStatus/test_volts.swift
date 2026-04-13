import Foundation
import IOKit

public struct PDProfile: Identifiable {
    public var id: Int { index }
    public var index: Int
    public var maxVoltage: Double
    public var maxCurrent: Double
}

public struct AdapterInfo {
    public var id: Int
    public var familyCode: Int
    public var name: String
    public var designWatts: Int
    public var realTimeWatts: Double
    public var activeProfileIndex: Int
    public var profiles: [PDProfile]
    
    public var current: Double?
    public var voltage: Double?
    public var watts: Double?
    
    public var activeProfile: PDProfile? {
        profiles.first { $0.index == activeProfileIndex }
    }
}

let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
if service != 0 {
    var properties: Unmanaged<CFMutableDictionary>?
    if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
        if let dict = properties?.takeRetainedValue() as? [String: Any] {
            let voltage = dict["Voltage"] as? Int ?? 0
            print("Battery Cell Voltage: \(Double(voltage) / 1000.0) V")

            if let adapterDetails = dict["AdapterDetails"] as? [String: Any] {
                print("Adapter DETAILS FOUND:")
                let currentAdapterVoltage = Double(adapterDetails["Voltage"] as? Int ?? 0) / 1000.0
                let currentAdapterCurrent = Double(adapterDetails["Current"] as? Int ?? 0) / 1000.0
                print("Adapter RealTime Voltage: \(currentAdapterVoltage) V")
                print("Adapter RealTime Current: \(currentAdapterCurrent) A")
                
                print("PD Profiles:")
                if let hvcMenu = adapterDetails["UsbHvcMenu"] as? [[String: Any]] {
                    for profile in hvcMenu {
                        let index = profile["Index"] as? Int ?? 0
                        let maxV = Double(profile["MaxVoltage"] as? Int ?? 0) / 1000.0
                        let maxC = Double(profile["MaxCurrent"] as? Int ?? 0) / 1000.0
                        print("  [\(index)] \(maxV)V  \(maxC)A")
                    }
                }
                
                let activeProfileIndex = adapterDetails["UsbHvcHvcIndex"] as? Int ?? 0
                print("Active Profile Index: \(activeProfileIndex)")
            } else {
                print("No AdapterDetails found.")
            }
        }
    }
}

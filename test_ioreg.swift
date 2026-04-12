import Foundation
import IOKit

func getSmartBatteryInfo() {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    if service != 0 {
        var properties: Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                // print keys
                for key in dict.keys { print(key) }
                print("Voltage: \(dict["Voltage"] ?? "nil")")
                print("Amperage: \(dict["Amperage"] ?? "nil")")
            }
        }
        IOObjectRelease(service)
    }
}
getSmartBatteryInfo()

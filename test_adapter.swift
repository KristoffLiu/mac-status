import Foundation
import IOKit

func getDetails() {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    if service != 0 {
        var properties: Unmanaged<CFMutableDictionary>?
        if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                print("AdapterDetails: \(dict["AdapterDetails"] ?? "nil")")
                print("ChargerData: \(dict["ChargerData"] ?? "nil")")
            }
        }
        IOObjectRelease(service)
    }
}
getDetails()

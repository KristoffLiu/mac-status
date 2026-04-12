import Foundation
import IOKit.ps

func getBatteryInfo() {
    let blob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let list = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as [CFTypeRef]
    if let first = list.first {
        let dict = IOPSGetPowerSourceDescription(blob, first).takeUnretainedValue() as? [String: Any]
        print(dict ?? "nil")
    } else {
        print("No battery")
    }
}
getBatteryInfo()

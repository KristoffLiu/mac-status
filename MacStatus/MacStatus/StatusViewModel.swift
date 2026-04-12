import Foundation
import IOKit
import Combine

class StatusViewModel: ObservableObject {
    @Published var voltage: Int = 0
    @Published var amperage: Int = 0
    @Published var isCharging: Bool = false
    @Published var currentCapacity: Int = 0
    @Published var maxCapacity: Int = 0
    @Published var designCapacity: Int = 0
    @Published var cycleCount: Int = 0
    @Published var temperature: Double = 0.0
    @Published var adapterWatts: Int = 0 // <-- Added for AC Power limit
    
    var wattage: Double {
        return abs(Double(voltage) / 1000.0 * Double(amperage) / 1000.0)
    }
    
    var powerDirection: String {
        if amperage > 0 { return "Charging" }
        if amperage < 0 { return "Discharging" }
        if adapterWatts > 0 { return "Adapter Power" }
        return "Idle"
    }

    private var timer: AnyCancellable?
    
    init() {
        updateBatteryInfo()
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBatteryInfo()
            }
    }
    
    func updateBatteryInfo() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess {
                if let dict = properties?.takeRetainedValue() as? [String: Any] {
                    DispatchQueue.main.async {
                        self.voltage = dict["Voltage"] as? Int ?? 0
                        
                        // Some Macs use InstantAmperage or Amperage. Try both.
                        let instantAmperage = dict["InstantAmperage"] as? Int ?? 0
                        let standardAmperage = dict["Amperage"] as? Int ?? 0
                        // Use Instant if available, else standard
                        self.amperage = instantAmperage != 0 ? instantAmperage : standardAmperage
                        
                        self.isCharging = dict["IsCharging"] as? Bool ?? false
                        self.currentCapacity = dict["CurrentCapacity"] as? Int ?? 0
                        self.maxCapacity = dict["MaxCapacity"] as? Int ?? 0
                        self.designCapacity = dict["DesignCapacity"] as? Int ?? 0
                        self.cycleCount = dict["CycleCount"] as? Int ?? 0
                        
                        let rawTemp = dict["Temperature"] as? Int ?? 0
                        self.temperature = Double(rawTemp) / 100.0 // mostly Temperature is in units of 0.01C
                        
                        if let adapterDetails = dict["AdapterDetails"] as? [String: Any] {
                            self.adapterWatts = adapterDetails["Watts"] as? Int ?? 0
                        } else {
                            self.adapterWatts = 0
                        }
                    }
                }
            }
            IOObjectRelease(service)
        }
    }
}

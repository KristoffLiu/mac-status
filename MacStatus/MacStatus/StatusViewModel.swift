import Foundation
import Combine

class StatusViewModel: ObservableObject {
    @Published var batteryData: BatteryData = .empty
    @Published var powerFlow: PowerFlowData = PowerFlowData(adapterPower: 0, batteryPower: 0, systemPower: 0, isCharging: false, isDischarging: false, topology: .topologyB)
    
    // For backwards compatibility and easier access during migration
    var voltage: Int { batteryData.voltage }
    var amperage: Int { batteryData.amperage }
    var isCharging: Bool { batteryData.isCharging }
    var currentCapacity: Int { batteryData.currentCapacity }
    var maxCapacity: Int { batteryData.maxCapacity }
    var designCapacity: Int { batteryData.designCapacity }
    var cycleCount: Int { batteryData.cycleCount }
    var temperature: Double { batteryData.temperature }
    var adapterWatts: Int { batteryData.adapterWatts }
    var powerDirection: String {
        if batteryData.amperage > 0 { return "Charging" }
        if batteryData.amperage < 0 { return "Discharging" }
        if batteryData.adapterWatts > 0 { return "Adapter Power" }
        return "Idle"
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Fetch synchronously on init to avoid initial 0% display
        let data = BatteryService.shared.fetchBatteryData()
        let flow = PowerCalculationService.shared.calculateFlow(from: data)
        self.batteryData = data
        self.powerFlow = flow
        self.lastBatteryFetch = Date()
        
        EnergyEfficiencyManager.shared.tickPublisher
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    private var lastBatteryFetch: Date = .distantPast
    private var isFetching = false
    
    private func refresh() {
        guard !isFetching else { return }
        isFetching = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // AppleSmartBattery queries (IOKit) can be slow (up to 500ms) on state changes.
            // We only query it every 2 seconds, but we query ultra-fast SMC data on every tick.
            let now = Date()
            var data = self.batteryData
            if now.timeIntervalSince(self.lastBatteryFetch) >= 2.0 {
                data = BatteryService.shared.fetchBatteryData()
                
                // Keep the state on the main thread consistent
                DispatchQueue.main.async { [weak self] in
                    self?.lastBatteryFetch = now
                }
            }
            
            // SMC fetch is instantaneous (~0.01ms) and will now never be blocked by battery PMU latency
            let flow = PowerCalculationService.shared.calculateFlow(from: data)
            
            DispatchQueue.main.async { [weak self] in
                self?.batteryData = data
                self?.powerFlow = flow
                self?.isFetching = false
            }
        }
    }
}

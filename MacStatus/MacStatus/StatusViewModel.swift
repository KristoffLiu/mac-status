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
        EnergyEfficiencyManager.shared.tickPublisher
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        // Also subscribe to high-fidelity M-series metrics
        MSeriesPowerService.shared.$metrics
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    private func refresh() {
        // Run IOKit call on background thread to prevent UI stutter
        DispatchQueue.global(qos: .userInitiated).async {
            let data = BatteryService.shared.fetchBatteryData()
            let mMetrics = MSeriesPowerService.shared.metrics
            let flow = PowerCalculationService.shared.calculateFlow(from: data, mSeriesMetrics: mMetrics)
            
            DispatchQueue.main.async {
                self.batteryData = data
                self.powerFlow = flow
            }
        }
    }
}

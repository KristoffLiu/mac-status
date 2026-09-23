import Foundation
import Combine

@MainActor
class StatusViewModel: ObservableObject {
    static let shared = StatusViewModel()
    @Published var batteryData: BatteryData = .empty
    @Published var powerFlow = PowerFlowData(adapterPower: 0, batteryPower: 0, systemPower: 0,
        isCharging: false, isDischarging: false, topology: .topologyB,
        adapterQuality: .unavailable, batteryQuality: .unavailable, systemQuality: .unavailable)

    var voltage: Int { batteryData.voltage }
    var amperage: Int { batteryData.amperage }
    var isCharging: Bool { powerFlow.isCharging }
    var currentCapacity: Int { batteryData.currentCapacity }
    var maxCapacity: Int { batteryData.maxCapacity }
    var designCapacity: Int { batteryData.designCapacity }
    var cycleCount: Int { batteryData.cycleCount }
    var temperature: Double { batteryData.temperature }
    var adapterWatts: Int { batteryData.adapterWatts }
    var capacityText: String { batteryData.isAvailable ? "\(currentCapacity)%" : "—" }
    var powerDirection: String {
        if powerFlow.readingsConflict { return "Unknown" }
        if powerFlow.isCharging { return "Charging" }
        if powerFlow.isDischarging { return "Discharging" }
        if powerFlow.hasAdapter { return "Adapter Power" }
        return "Unknown"
    }

    private var cancellables = Set<AnyCancellable>()
    private var isFetching = false
    private var refreshPending = false
    private var powerPresentationReducer = PowerPresentationReducer()

    init(startMonitoring: Bool = true) {
        guard startMonitoring else { return }
        EnergyEfficiencyManager.shared.tickPublisher
            .sink { [weak self] _ in self?.refresh() }.store(in: &cancellables)
        EnergyEfficiencyManager.shared.$policy
            .dropFirst()
            .sink { [weak self] _ in self?.powerPresentationReducer.reset() }
            .store(in: &cancellables)
        refresh()
    }

    private func refresh() {
        guard !isFetching else { refreshPending = true; return }
        isFetching = true
        Task { [weak self] in
            let policy = EnergyEfficiencyManager.shared.policy
            let snapshot = await StatusSnapshotCoordinator.shared.sample(for: policy)
            guard let self else { return }
            let data = snapshot.battery
            let rawFlow = PowerCalculationService.shared.calculateFlow(from: data, sensors: snapshot.sensors)
            let flow = powerPresentationReducer.reduce(
                flow: rawFlow,
                battery: data,
                expectedInterval: policy.tickInterval ?? 2
            )
            if batteryData != data { batteryData = data }
            if powerFlow != flow { powerFlow = flow }
            isFetching = false
            if refreshPending {
                refreshPending = false
                if EnergyEfficiencyManager.shared.policy.tickInterval != nil { refresh() }
            }
        }
    }
}

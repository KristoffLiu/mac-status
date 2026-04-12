import Foundation
import Combine

struct MSeriesPowerMetrics {
    var cpuWatts: Double = 0.0
    var gpuWatts: Double = 0.0
    var aneWatts: Double = 0.0
    var totalSystemWatts: Double = 0.0
    
    var totalInternalWatts: Double {
        return cpuWatts + gpuWatts + aneWatts
    }
}

class MSeriesPowerService: ObservableObject {
    static let shared = MSeriesPowerService()
    
    @Published var metrics = MSeriesPowerMetrics()
    
    private let reader = IOReportReader()
    private var timer: AnyCancellable?
    private let interval: TimeInterval = 0.5
    
    private init() {
        start()
    }
    
    func start() {
        // We poll every 0.5 seconds for snappy UI updates
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMetrics()
            }
        
        // Initial fetch
        updateMetrics()
    }
    
    private func updateMetrics() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let cpuData = self.reader.getPowerDeltas(group: "Energy Model", subgroup: "CPU Complex PerformanceStates", pollInterval: self.interval)
            let gpuData = self.reader.getPowerDeltas(group: "Energy Model", subgroup: "GPU PerformanceStates", pollInterval: self.interval)
            let aneData = self.reader.getPowerDeltas(group: "Energy Model", subgroup: "ANE PerformanceStates", pollInterval: self.interval)
            
            // On Apple Silicon, we can sum the component energy.
            // For total system draw including display/backlight, we often need PMU sensors.
            // However, summing CPU/GPU/ANE gives a very accurate "Workload Wattage".
            
            let cpuWatts = cpuData.values.reduce(0, +)
            let gpuWatts = gpuData.values.reduce(0, +)
            let aneWatts = aneData.values.reduce(0, +)
            
            // Fetch total system power if available via common PMU entries
            // Falling back to a heuristic: System Draw = Components + Idle Base (usually 2-5W)
            // Or if we have AdapterPower from BatteryService, we can use that as the lid-open total.
            
            DispatchQueue.main.async {
                self.metrics = MSeriesPowerMetrics(
                    cpuWatts: cpuWatts,
                    gpuWatts: gpuWatts,
                    aneWatts: aneWatts,
                    totalSystemWatts: cpuWatts + gpuWatts + aneWatts + 3.0 // 3W base idle for M-series
                )
            }
        }
    }
}

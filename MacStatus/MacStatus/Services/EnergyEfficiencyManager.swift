import Foundation
import Combine

enum AppState {
    case background // Popover closed
    case active     // Popover opened
}

class EnergyEfficiencyManager: ObservableObject {
    static let shared = EnergyEfficiencyManager()
    
    @Published var appState: AppState = .background {
        didSet {
            setupTimer()
        }
    }
    
    // Publisher that emits when data should be updated
    let tickPublisher = PassthroughSubject<Void, Never>()
    
    private var timerCancellable: AnyCancellable?
    
    private init() {
        setupTimer()
    }
    
    private func setupTimer() {
        timerCancellable?.cancel()
        
        let interval: TimeInterval = (appState == .active) ? 1.0 : 10.0 // 1s when active, 10s when background
        
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickPublisher.send()
            }
        
        // Immediately fetch data on state change
        tickPublisher.send()
    }
}

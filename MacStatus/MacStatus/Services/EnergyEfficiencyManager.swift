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
    
    @Published var activeUpdateInterval: Double {
        didSet {
            UserDefaults.standard.set(activeUpdateInterval, forKey: "activeUpdateInterval")
            setupTimer()
        }
    }
    
    // Publisher that emits when data should be updated
    let tickPublisher = PassthroughSubject<Void, Never>()
    
    private var timerCancellable: AnyCancellable?
    
    private init() {
        let saved = UserDefaults.standard.double(forKey: "activeUpdateInterval")
        self.activeUpdateInterval = saved > 0 ? saved : 1.0
        setupTimer()
    }
    
    private func setupTimer() {
        timerCancellable?.cancel()
        
        // When active (Popover is open), poll at user-defined interval
        let interval: TimeInterval = (appState == .active) ? activeUpdateInterval : 10.0
        
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickPublisher.send()
            }
        
        // Immediately fetch data on state change
        tickPublisher.send()
    }
}

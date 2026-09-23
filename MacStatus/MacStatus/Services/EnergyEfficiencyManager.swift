import AppKit
import Combine
import IOKit.ps

nonisolated enum AppState { case background, active }

@MainActor
final class EnergyEfficiencyManager: ObservableObject {
    static let shared = EnergyEfficiencyManager()
    @Published var appState: AppState = .background { didSet { updatePolicy() } }
    @Published var activeUpdateInterval: Double {
        didSet {
            UserDefaults.standard.set(SamplingPolicy.clampInterval(activeUpdateInterval), forKey: AppPreferenceKeys.activeUpdateInterval)
            updatePolicy()
        }
    }
    @Published private(set) var policy = SamplingPolicy()
    let tickPublisher = PassthroughSubject<Void, Never>()
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var sleeping = false
    private var powerSourceNotification: CFRunLoopSource?

    private init() {
        let saved = UserDefaults.standard.double(forKey: AppPreferenceKeys.activeUpdateInterval)
        activeUpdateInterval = SamplingPolicy.clampInterval(saved)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updatePolicy() }
            .store(in: &cancellables)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in self?.sleeping = true; self?.updatePolicy() }
            .store(in: &cancellables)
        workspace.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in self?.sleeping = false; self?.updatePolicy() }
            .store(in: &cancellables)
        powerSourceNotification = IOPSNotificationCreateRunLoopSource({ _ in
            Task { @MainActor in EnergyEfficiencyManager.shared.requestUpdate() }
        }, nil)?.takeRetainedValue()
        if let source = powerSourceNotification { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        updatePolicy()
    }

    func requestUpdate() {
        if !sleeping { tickPublisher.send() }
    }

    private func updatePolicy() {
        let defaults = UserDefaults.standard
        let next = SamplingPolicy(
            panelVisible: appState == .active, sleeping: sleeping,
            widgets: Set(defaults.stringArray(forKey: AppPreferenceKeys.panelWidgetOrder) ?? AppPreferences.defaultWidgetOrder),
            threeStage: defaults.bool(forKey: AppPreferenceKeys.powerFlowThreeStage),
            flowStyle: defaults.string(forKey: AppPreferenceKeys.powerFlowStyle) ?? "cards", activeInterval: activeUpdateInterval,
            backgroundInterval: SamplingPolicy.clampBackgroundInterval(defaults.double(forKey: AppPreferenceKeys.menuUpdateInterval))
        )
        guard next != policy || timerCancellable == nil else { return }
        policy = next
        timerCancellable?.cancel()
        timerCancellable = nil
        if let interval = next.tickInterval {
            timerCancellable = Timer.publish(every: interval, tolerance: min(1, interval * 0.1), on: .main, in: .common)
                .autoconnect().sink { [weak self] _ in self?.tickPublisher.send() }
            // Let policy subscribers cancel/start their work before the first tick.
            DispatchQueue.main.async { [weak self] in self?.requestUpdate() }
        }
    }
}

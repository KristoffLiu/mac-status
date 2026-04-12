import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var viewModel = StatusViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    private var globalEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = MainPanelView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: rootView)
        
        // Setup status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = .monospacedDigitSystemFont(ofSize: 0, weight: .regular)
            button.imagePosition = .imageLeft
        }
        
        setupObservers()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    private func showPanel() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if globalEventMonitor == nil {
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hidePanel()
            }
        }
    }
    
    private func hidePanel() {
        popover.performClose(nil)
        
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    private func setupObservers() {
        Publishers.CombineLatest(
            viewModel.$batteryData,
            viewModel.$powerFlow
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.updateStatusItem()
            // We might want to recalculate size and reposition here if dynamic
            // But leaving simple for now
        }
        .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
            
        updateStatusItem()
    }
    
    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        
        let showPercent = UserDefaults.standard.object(forKey: "showPercentage") as? Bool ?? true
        let showWatt = UserDefaults.standard.object(forKey: "showWattage") as? Bool ?? false
        
        let imageName = viewModel.isCharging ? "battery.100.bolt" : "battery.100"
        let conf = NSImage.SymbolConfiguration(scale: .medium)
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Battery")?.withSymbolConfiguration(conf)
        
        var textComponents: [String] = []
        if showPercent {
            textComponents.append("\(viewModel.currentCapacity)%")
        }
        if showWatt {
            if viewModel.powerFlow.systemPower < 0 {
                textComponents.append(" -- W")
            } else {
                textComponents.append(String(format: " %.1fW", viewModel.powerFlow.systemPower))
            }
        }
        
        button.title = textComponents.joined(separator: " ")
    }
    
    // Prevent the entire app from quitting when the Settings window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // Prevent SwiftUI from automatically opening the Settings window when the app is activated (e.g., via menu bar click)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
}

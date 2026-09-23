import Cocoa
import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var panel: NSPanel!
    private var eventMonitor: Any?
    private var localEventMonitor: Any?
    
    var viewModel: StatusViewModel = .shared
    
    var menuBarIsDark: Bool {
        // Use the status item button's appearance when available; it reflects the actual menu bar theme.
        let appearance = statusItem?.button?.effectiveAppearance ?? NSApp.effectiveAppearance
        return appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
    }
    
    override init() {
        super.init()
    }
    
    // Prevent the entire app from terminating when the MenuBar popover or Settings window is closed!
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppPreferences.migrate()
        _ = SystemMonitorService.shared
        _ = AppEnergyMonitor.shared
        _ = HighPowerAppsService.shared

        // Initialize Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
        }
        
        // Initialize Panel
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                        styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                        backing: .buffered, defer: false)
        let hostingController = NSHostingController(rootView: MainPanelView(viewModel: viewModel))
        panel.contentViewController = hostingController
        // Resize panel to fit content automatically
        panel.setContentSize(hostingController.view.fittingSize)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        
        // Monitor for outside clicks to close the popover automatically
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // Default is true if not set
            let autoHide = UserDefaults.standard.object(forKey: AppPreferenceKeys.autoHidePanel) == nil ? true : UserDefaults.standard.bool(forKey: AppPreferenceKeys.autoHidePanel)
            if autoHide {
                if let panel = self?.panel, panel.isVisible {
                    self?.hidePanel()
                }
            }
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            if event.type == .keyDown, event.keyCode == 53 {
                self.hidePanel()
                return nil
            }
            let autoHide = UserDefaults.standard.object(forKey: AppPreferenceKeys.autoHidePanel) == nil || UserDefaults.standard.bool(forKey: AppPreferenceKeys.autoHidePanel)
            if event.type != .keyDown, event.window != self.panel, event.window != self.statusItem.button?.window, autoHide {
                self.hidePanel()
            }
            return event
        }

        // Listen for open panel notifications
        NotificationCenter.default.addObserver(self, selector: #selector(showPopoverForEditing), name: NSNotification.Name("OpenMenuBarPopover"), object: nil)
        
        // Listen for UserDefaults changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                let theme = UserDefaults.standard.string(forKey: AppPreferenceKeys.panelTheme) ?? "system"
                self?.applyPanelTheme(theme)
                // Force a render update when settings change to eliminate any delay
                DispatchQueue.main.async {
                    self?.updateStatusItemImage(force: true)
                }
            }.store(in: &cancellables)
        
        // Initial Theme
        applyPanelTheme(UserDefaults.standard.string(forKey: AppPreferenceKeys.panelTheme) ?? "system")
        
        // Listen for appearance changes (both app-level and system-wide)
        NSApp.publisher(for: \.effectiveAppearance).sink { [weak self] _ in
            self?.updateStatusItemImage(force: true)
        }.store(in: &cancellables)

        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(interfaceThemeChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )

        // Render only when data changes, skipping unnecessary bitmap generations
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Need to dispatch after to guarantee values have propagated
                DispatchQueue.main.async {
                    self?.updateStatusItemImage()
                }
            }
            .store(in: &cancellables)
        
        // Initial draw — delay slightly so the button's effectiveAppearance has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateStatusItemImage(force: true)
        }
    }

    @objc private func interfaceThemeChanged() {
        // System theme may take a moment to propagate to the status bar button.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateStatusItemImage(force: true)
        }
    }

    private var cancellables = Set<AnyCancellable>()
    
    private func applyPanelTheme(_ theme: String) {
        if theme == "dark" {
            panel.appearance = NSAppearance(named: .darkAqua)
        } else if theme == "light" {
            panel.appearance = NSAppearance(named: .aqua)
        } else {
            panel.appearance = nil
        }
    }
    
    @objc private func handleStatusItemClick(_ sender: AnyObject?) {
        let button: MenuBarMouseButton = NSApp.currentEvent?.type == .rightMouseUp ? .right : .left
        switch MenuBarInteraction.command(
            for: button,
            rightClickAction: AppPreferences.rightClickAction()
        ) {
        case .togglePanel:
            if panel.isVisible {
                hidePanel()
            } else {
                showPanel()
            }
        case .terminate:
            NSApp.terminate(nil)
        }
    }
    
    @objc func showPopoverForEditing() {
        if !panel.isVisible {
            showPanel()
        }
    }
    
    private func hidePanel() {
        EnergyEfficiencyManager.shared.appState = .background
        
        let enableAnim = UserDefaults.standard.object(forKey: AppPreferenceKeys.enablePanelAnimations) == nil ? true : UserDefaults.standard.bool(forKey: AppPreferenceKeys.enablePanelAnimations)
        
        if enableAnim {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                panel.animator().alphaValue = 0.0
            }, completionHandler: {
                self.panel.orderOut(nil)
            })
        } else {
            panel.orderOut(nil)
        }
    }
    
    private func showPanel() {
        guard let button = statusItem.button, let window = button.window else { return }
        EnergyEfficiencyManager.shared.appState = .active
        
        // Refresh fitting size in case of layout changes
        if let hostingController = panel.contentViewController as? NSHostingController<MainPanelView> {
            panel.setContentSize(hostingController.view.fittingSize)
        }
        
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenRect = window.convertToScreen(buttonFrame)
        
        let visible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? screenRect
        let x = max(visible.minX + 8, min(screenRect.midX - panel.frame.width / 2, visible.maxX - panel.frame.width - 8))
        let y = max(visible.minY + 8, screenRect.minY - panel.frame.height - 8)
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        
        let enableAnim = UserDefaults.standard.object(forKey: AppPreferenceKeys.enablePanelAnimations) == nil ? true : UserDefaults.standard.bool(forKey: AppPreferenceKeys.enablePanelAnimations)
        if enableAnim {
            panel.alphaValue = 0.0
            panel.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                panel.animator().alphaValue = 1.0
            }
        } else {
            panel.alphaValue = 1.0
            panel.makeKeyAndOrderFront(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }

    private var lastRenderedBattery: BatteryData?
    private var lastRenderedFlow: PowerFlowData?
    private var lastRenderedThemeDark: Bool?

    @MainActor
    private func updateStatusItemImage(force: Bool = false) {
        let isDark = menuBarIsDark
        statusItem.button?.toolTip = viewModel.powerFlow.readingsConflict ? String(localized: "传感器读数暂不一致") : "MacStatus · \(viewModel.capacityText)"
        
        var battery = viewModel.batteryData
        battery.sampledAt = nil // A timestamp alone does not change the label.
        guard force || lastRenderedBattery != battery || lastRenderedFlow != viewModel.powerFlow || lastRenderedThemeDark != isDark else { return }
        lastRenderedBattery = battery
        lastRenderedFlow = viewModel.powerFlow
        lastRenderedThemeDark = isDark

        // Create the isolated battery graphic
        let batteryView = IsolatedBatteryGraphicRenderer(viewModel: viewModel)
            .environment(\.colorScheme, isDark ? .dark : .light)

        let batteryRenderer = ImageRenderer(content: batteryView.padding(1))
        batteryRenderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        batteryRenderer.isOpaque = false // Transparent background
        
        var batteryImage: NSImage? = nil
        if let nsImage = batteryRenderer.nsImage {
            let fillStyle = UserDefaults.standard.string(forKey: AppPreferenceKeys.batteryFillStyle) ?? "monochrome"
            if fillStyle == "status_color" {
                nsImage.isTemplate = false
            } else {
                nsImage.isTemplate = true
            }
            batteryImage = nsImage
        }
        
        // Now wrap the entire label renderer (battery + text) and output it as a single status bar image
        let labelView = MenuBarLabelRendererView(viewModel: viewModel, generatedMenuImage: batteryImage)
            .environment(\.colorScheme, isDark ? .dark : .light)
            .foregroundColor(isDark ? .white : .black)
        let labelRenderer = ImageRenderer(content: labelView)
        labelRenderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        labelRenderer.isOpaque = false
        
        if let finalImage = labelRenderer.nsImage {
            // Because we pass the colors correctly with the environment modifier,
            // we must disable template mode so the customized standard colored text renders correctly.
            finalImage.isTemplate = false 
            self.statusItem.button?.image = finalImage
        }
    }
}

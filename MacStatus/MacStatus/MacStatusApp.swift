import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @StateObject private var viewModel = StatusViewModel()
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showWattage") private var showWattage = false

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // Dummy hidden MenuBarExtra scene to intercept SwiftUI's default start-up window behavior.
        // SwiftUI won't automatically open the secondary 'Window' scene on app launch,
        // and since `isInserted` is false, this MenuBarExtra won't show an icon either.
        MenuBarExtra("Hidden", systemImage: "star", isInserted: .constant(false)) {
            EmptyView()
        }
        
        MenuBarExtra {
            MainPanelView(viewModel: viewModel)
        } label: {
            menuBarLabel()
        }
        .menuBarExtraStyle(.window) // This gives the native popover with the 'tip' pointing to the menu bar!
        
        // Settings Window with Sidebar (Single Instance)
        Window("MacStatus 设置", id: "settings") {
            SettingsView()
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
    
    @ViewBuilder
    private func menuBarLabel() -> some View {
        HStack(spacing: 2) {
            Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")
                .imageScale(.medium)
            
            if showPercentage {
                Text("\(viewModel.currentCapacity)%")
                    .font(.system(.body, design: .rounded).monospacedDigit())
            }
            
            if showWattage {
                if viewModel.powerFlow.systemPower < 0 {
                    Text(" -- W")
                        .font(.system(.body, design: .rounded).monospacedDigit())
                } else {
                    Text(String(format: " %.1fW", viewModel.powerFlow.systemPower))
                        .font(.system(.body, design: .rounded).monospacedDigit())
                }
            }
        }
    }
}

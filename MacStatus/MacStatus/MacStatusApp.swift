import SwiftUI

@main
struct MacStatusApp: App {
    @StateObject private var viewModel = StatusViewModel()
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showDetails") private var showDetails = false

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MainPanelView(viewModel: viewModel)
        } label: {
            menuBarLabel()
        }
        .menuBarExtraStyle(.window) // This enables the nice custom popover View
        
        // Settings Window with Sidebar (Single Instance)
        Window("MacStatus 设置", id: "settings") {
            SettingsView()
                .toolbarBackground(.hidden, for: .windowToolbar)
        }
        .windowStyle(.hiddenTitleBar)
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

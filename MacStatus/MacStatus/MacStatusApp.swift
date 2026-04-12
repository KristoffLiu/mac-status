import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @StateObject private var viewModel = StatusViewModel()
    
    // Status Bar Configuration
    @AppStorage("menuBarIconStyle") private var menuBarIconStyle = "battery"
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = false
    @AppStorage("showCycles") private var showCycles = false
    @AppStorage("showTemperature") private var showTemperature = false
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showVoltage") private var showVoltage = false
    @AppStorage("showAmperage") private var showAmperage = false
    @AppStorage("menuItemSpacing") private var menuItemSpacing: Double = 4

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
        
        // Main Application Window with Sidebar
        Window("MacStatus", id: "settings") {
            MainWindowView()
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
    
    @ViewBuilder
    private func menuBarLabel() -> some View {
        HStack(spacing: menuItemSpacing) {
            
            if menuBarIconStyle == "battery" {
                Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")
                    .imageScale(.medium)
            }
            
            if showPercentage {
                Text("\(viewModel.currentCapacity)%")
                    .font(.system(.body, design: .rounded).monospacedDigit())
            }
            
            if showChargingStatus {
                Image(systemName: viewModel.isCharging ? "bolt.fill" : "bolt.slash.fill")
            }
            
            if showCycles {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.3.path").font(.caption)
                    Text("\(viewModel.cycleCount)")
                }
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundColor(.secondary)
            }
            
            if showTemperature {
                HStack(spacing: 2) {
                    Text(String(format: "%.0f°C", viewModel.temperature))
                }
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
            
            if showVoltage {
                Text(String(format: "%.1fV", Double(viewModel.voltage) / 1000.0))
                    .font(.system(.body, design: .rounded).monospacedDigit())
            }
            
            if showAmperage {
                Text(String(format: "%.1fA", Double(abs(viewModel.amperage)) / 1000.0))
                    .font(.system(.body, design: .rounded).monospacedDigit())
            }
        }
    }
}

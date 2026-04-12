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
            PanelContainerView {
                // Header (App Title & Preferences)
                HStack {
                    Text("MacStatus")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Toggle(isOn: $showDetails) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                    .toggleStyle(.button)
                    .font(.caption2)
                    
                    Toggle("％", isOn: $showPercentage)
                        .toggleStyle(.button)
                        .font(.caption2)
                    Toggle("W", isOn: $showWattage)
                        .toggleStyle(.button)
                        .font(.caption2)
                }
                .padding(.horizontal, 4)
                
                // Unified Power & Battery Card
                VStack(spacing: 0) {
                    // Sankey Flow Section
                    SankeyPowerFlowView(powerFlow: viewModel.powerFlow)
                    
                    if showDetails {
                        // Subtle separator
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                        
                        // Detail Grid Section
                        DetailGridModule(batteryData: viewModel.batteryData)
                        
                        // Subtle separator for High Power Apps
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                        
                        // High Power Apps Section
                        HighPowerAppsModule()
                    }
                }
                .moduleCardStyle()
                
                // Footer
                HStack {
                    Button(action: {
                        openWindow(id: "settings")
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                EnergyEfficiencyManager.shared.appState = .active
            }
            .onDisappear {
                EnergyEfficiencyManager.shared.appState = .background
            }
        } label: {
            menuBarLabel()
        }
        .menuBarExtraStyle(.window) // This enables the nice custom popover View
        
        // Settings Window with Sidebar (Single Instance)
        Window("MacStatus 设置", id: "settings") {
            SettingsView()
                .background(VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow))
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

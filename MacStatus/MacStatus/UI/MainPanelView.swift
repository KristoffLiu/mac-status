import SwiftUI

struct MainPanelView: View {
    @ObservedObject var viewModel: StatusViewModel
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showDetails") private var showDetails = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
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
    }
}

#Preview {
    // 注入一个临时的 viewModel 供画布预览
    MainPanelView(viewModel: StatusViewModel())
}

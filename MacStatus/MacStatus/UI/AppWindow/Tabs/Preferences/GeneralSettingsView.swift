import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var energyManager = EnergyEfficiencyManager.shared
    
    var body: some View {
        Form {
            
            Section("Refresh Rate") {
                Picker("Refresh Interval While Panel Open", selection: $energyManager.activeUpdateInterval) {
                    Text("0.2 Secs (Ultra Fast)").tag(0.2)
                    Text("0.5 Secs (Fast)").tag(0.5)
                    Text("1.0 Secs (Normal)").tag(1.0)
                    Text("2.0 Secs (Power Saving)").tag(2.0)
                }
                .pickerStyle(.menu)
                Text("Refresh rate automatically drops to 10 seconds in the background when the panel is closed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通用")
    }
}

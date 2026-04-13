import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section("Dashboard Style") {
                Text(LocalizedStringKey("Sankey Power Flow (Enabled)"))
                    .foregroundColor(.secondary)
            }
            
            Section("Color Scheme") {
                Text(LocalizedStringKey("System"))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance Settings")
    }
}

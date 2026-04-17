import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "cpu.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.blue.gradient)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text("MacStatus")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("Version 1.0.0 (Build 100)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section("App Features") {
                Text("A minimalist tool to monitor your Mac's power and battery status in real-time.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("Links & Support") {
                LabeledContent("Developer", value: "Kristoff")
                LabeledContent("Official Website", value: "github.com/kristoff")
            }
            
            Section {
                // Empty section for spacing or future links
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("© 2024 Kristoff. All rights reserved.")
                    Text("Powered by SwiftUI.")
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("关于")
    }
}

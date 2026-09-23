import SwiftUI
import AppKit

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
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") (Build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section("App Features") {
                Text("在菜单栏查看电池、功率流向和系统状态。估算读数会单独标注。")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("Links & Support") {
                LabeledContent("Developer", value: "Kristoff")
                if let license = Bundle.main.url(forResource: "LICENSE", withExtension: "txt") {
                    Button("MIT License") {
                        NSWorkspace.shared.open(license)
                    }
                }
                if let address = Bundle.main.object(forInfoDictionaryKey: "MacStatusSupportURL") as? String,
                   let url = URL(string: address), url.scheme == "https" {
                    Link("反馈与支持", destination: url)
                }
            }
            
            Section {
                // Empty section for spacing or future links
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("© \(String(Calendar.current.component(.year, from: Date()))) Kristoff.")
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

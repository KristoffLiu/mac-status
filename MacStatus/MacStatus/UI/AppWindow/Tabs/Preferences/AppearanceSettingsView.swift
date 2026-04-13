import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("面板组件定制")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("在这里可以对各个面板的组件进行定制。")
                    .foregroundColor(.secondary)
                
                // Placeholder for panel components settings
                Form {
                    Section("可用组件") {
                        Toggle("电池组件", isOn: .constant(true))
                        Toggle("电源适配器", isOn: .constant(true))
                        Toggle("电池温度", isOn: .constant(true))
                    }
                }
                .formStyle(.grouped)
                .frame(minHeight: 200)
            }
            .padding(32)
        }
        .navigationTitle("面板")
    }
}

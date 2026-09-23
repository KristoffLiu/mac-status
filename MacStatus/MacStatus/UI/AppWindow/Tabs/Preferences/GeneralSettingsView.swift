import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @StateObject private var loginItem = LoginItemService()
    @ObservedObject private var energyManager = EnergyEfficiencyManager.shared
    
    var body: some View {
        Form {
            Section("启动") {
                Toggle("登录时启动", isOn: Binding(get: { loginItem.isRegistered }, set: { loginItem.setEnabled($0) }))
                if loginItem.status == .requiresApproval {
                    Text("已注册，等待在系统设置中允许登录时启动。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("打开登录项设置") { SMAppService.openSystemSettingsLoginItems() }
                }
                if let error = loginItem.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
                }
            }
            
            Section("Refresh Rate") {
                Picker("Refresh Interval While Panel Open", selection: $energyManager.activeUpdateInterval) {
                    Text("0.2 Secs (Ultra Fast)").tag(0.2)
                    Text("0.5 Secs (Fast)").tag(0.5)
                    Text("1.0 Secs (Normal)").tag(1.0)
                    Text("2.0 Secs (Power Saving)").tag(2.0)
                }
                .pickerStyle(.menu)
                Text("面板关闭后仅保留菜单栏采样，后台间隔可在菜单栏设置中调整（默认 10 秒）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通用")
        .onAppear { loginItem.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in loginItem.refresh() }
    }
}

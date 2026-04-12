import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .general
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    enum SettingsTab: String, CaseIterable, Hashable {
        case general = "通用"
        case appearance = "外观"
        case about = "关于"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
        } detail: {
            Group {
                if let tab = selectedTab {
                    switch tab {
                    case .general:
                        GeneralSettingsView()
                    case .appearance:
                        AppearanceSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                } else {
                    Text("请选择左侧菜单")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectBackground(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showWattage") private var showWattage = false
    
    @ObservedObject private var energyManager = EnergyEfficiencyManager.shared
    
    var body: some View {
        Form {
            Section("菜单栏显示") {
                Toggle("显示电量百分比", isOn: $showPercentage)
                Toggle("显示实时功率 (W)", isOn: $showWattage)
            }
            
            Section("刷新频率") {
                Picker("面板打开时刷新间隔", selection: $energyManager.activeUpdateInterval) {
                    Text("0.2 秒 (极速)").tag(0.2)
                    Text("0.5 秒 (较快)").tag(0.5)
                    Text("1.0 秒 (正常)").tag(1.0)
                    Text("2.0 秒 (省电)").tag(2.0)
                }
                .pickerStyle(.menu)
                Text("面板关闭后会在后台自动降速为 10 秒刷新")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通用设置")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section("仪表盘样式") {
                Text("桑基图能量流 (已启用)")
                    .foregroundColor(.secondary)
            }
            
            Section("配色方案") {
                Text("跟随系统")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("外观设置")
    }
}

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
                        Text("版本 1.0.0 (Build 100)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section("应用说明") {
                Text("实时监控 Mac 电源与电池状态的极简工具，为您提供精确的系统功耗与电池健康分析。")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("链接与支持") {
                LabeledContent("开发者", value: "Kristoff")
                LabeledContent("官方网站", value: "github.com/kristoff")
            }
            
            Section {
                // Empty section for spacing or future links
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("© 2024 Kristoff. All rights reserved.")
                    Text("由 SwiftUI 提供驱动。")
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

#Preview {
    SettingsView()
}

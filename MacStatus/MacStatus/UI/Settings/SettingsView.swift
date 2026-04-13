import SwiftUI
import Combine

struct MainWindowView: View {
    @State private var selectedTab: MainWindowTab? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    enum MainWindowTab: String, CaseIterable, Hashable {
        case dashboard = "仪表盘"
        case general = "通用"
        case menuBar = "菜单栏"
        case appearance = "外观"
        case about = "关于"
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .general: return "gearshape"
            case .menuBar: return "menubar.rectangle"
            case .appearance: return "paintbrush"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(MainWindowTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(LocalizedStringKey(tab.rawValue), systemImage: tab.icon)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        selectedTab = .general
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        } detail: {
            Group {
                if let tab = selectedTab {
                    switch tab {
                    case .dashboard:
                        DashboardSettingsView()
                    case .general:
                        GeneralSettingsView()
                    case .menuBar:
                        MenuBarSettingsView()
                    case .appearance:
                        AppearanceSettingsView()
                    case .about:
                        AboutSettingsView()
                    }
                } else {
                    Text("Select a menu on the left")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectBackground(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

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
        .navigationTitle("General Settings")
    }
}

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
        .navigationTitle("About")
    }
}

// MARK: - 菜单栏设置

// MARK: - 菜单栏设置

struct MenuBarSettingsView: View {
    @AppStorage("menuBarIconStyle") private var menuBarIconStyle = "battery"
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = false
    
    // 主图标选项
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    
    // 电池健康
    @AppStorage("showMaxCapacity") private var showMaxCapacity = false
    @AppStorage("showMacOSCapacity") private var showMacOSCapacity = false
    @AppStorage("showMacOSCondition") private var showMacOSCondition = false
    @AppStorage("showCycles") private var showCycles = false
    
    // 电池规格
    @AppStorage("showTemperature") private var showTemperature = false
    @AppStorage("showTimeRemaining") private var showTimeRemaining = false
    @AppStorage("showAmperage") private var showAmperage = false
    @AppStorage("showVoltage") private var showVoltage = false
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showSystemLoad") private var showSystemLoad = false
    
    // 电源适配器规格
    @AppStorage("showAdapterCurrent") private var showAdapterCurrent = false
    @AppStorage("showAdapterVoltage") private var showAdapterVoltage = false
    @AppStorage("showAdapterPower") private var showAdapterPower = false
    
    // AlDente 状态
    @AppStorage("showAlDenteCalibration") private var showAlDenteCalibration = false
    @AppStorage("showAlDenteOverheat") private var showAlDenteOverheat = false
    @AppStorage("showAlDenteSailing") private var showAlDenteSailing = false
    @AppStorage("showAlDenteFull") private var showAlDenteFull = false
    
    // 底部参数
    @AppStorage("menuItemSpacing") private var menuItemSpacing: Double = 4
    @AppStorage("menuUpdateInterval") private var menuUpdateInterval: Double = 2
    @AppStorage("menuRightClickAction") private var menuRightClickAction = "同左击"

    var body: some View {
        Form {
            Section("主图标样式") {
                Picker("样式", selection: $menuBarIconStyle) {
                    Text("不要显示").tag("none")
                    Text("AlDente 图标").tag("aldente_icon")
                    Text("AlDente 状态").tag("aldente_status")
                    Text("macOS 原生").tag("battery")
                    Text("iOS 原生").tag("ios_native")
                    Text("macOS 彩色").tag("macos_color")
                }
            }

            Section("主图标选项") {
                Toggle("显示百分比", isOn: $showPercentage)
                Toggle("低电量模式颜色", isOn: $iconLowPowerColor)
                Toggle("充电状态", isOn: $showChargingStatus)
            }
            
            Section("电池健康") {
                Toggle("最大容量", isOn: $showMaxCapacity)
                Toggle("macOS 容量", isOn: $showMacOSCapacity)
                Toggle("macOS 条件", isOn: $showMacOSCondition)
                Toggle("循环次数", isOn: $showCycles)
            }
            
            Section("电池规格") {
                Toggle("温度", isOn: $showTemperature)
                Toggle("满载/剩余时间", isOn: $showTimeRemaining)
                Toggle("电流", isOn: $showAmperage)
                Toggle("电压", isOn: $showVoltage)
                Toggle("电源", isOn: $showWattage)
                Toggle("系统负载", isOn: $showSystemLoad)
            }
            
            Section("电源适配器规格") {
                Toggle("当前", isOn: $showAdapterCurrent)
                Toggle("电压", isOn: $showAdapterVoltage)
                Toggle("电源", isOn: $showAdapterPower)
            }
            
            Section("AlDente 状态") {
                Toggle("校准模式", isOn: $showAlDenteCalibration)
                Toggle("过热保护", isOn: $showAlDenteOverheat)
                Toggle("航海模式", isOn: $showAlDenteSailing)
                Toggle("充满", isOn: $showAlDenteFull)
            }
            
            Section("菜单栏偏好设置") {
                HStack {
                    Text("菜单项间距")
                    Slider(value: $menuItemSpacing, in: 0...20, step: 1)
                    Text("\(Int(menuItemSpacing))")
                        .monospacedDigit()
                        .frame(width: 24, alignment: .trailing)
                }
                
                HStack {
                    Text("菜单更新间隔")
                    Slider(value: $menuUpdateInterval, in: 2...20, step: 1)
                    Text("\(Int(menuUpdateInterval)) 秒")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                
                Picker("菜单栏右击", selection: $menuRightClickAction) {
                    Text("同左击").tag("同左击")
                    Text("退出应用").tag("退出应用")
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("重置") {
                        menuItemSpacing = 4
                        menuUpdateInterval = 2
                    }
                    .buttonStyle(.borderless)
                    
                    Button("全部清除") {
                        menuBarIconStyle = "none"
                        showPercentage = false
                        showChargingStatus = false
                        iconLowPowerColor = false
                        showMaxCapacity = false
                        showMacOSCapacity = false
                        showMacOSCondition = false
                        showCycles = false
                        showTemperature = false
                        showTimeRemaining = false
                        showAmperage = false
                        showVoltage = false
                        showWattage = false
                        showSystemLoad = false
                        showAdapterCurrent = false
                        showAdapterVoltage = false
                        showAdapterPower = false
                        showAlDenteCalibration = false
                        showAlDenteOverheat = false
                        showAlDenteSailing = false
                        showAlDenteFull = false
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("菜单栏属性")
        .safeAreaInset(edge: .top) {
            // --- 沉浸式浮动预览卡片 ---
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "eyes")
                        .foregroundColor(.blue)
                    Text("实时体验预览")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack(spacing: menuItemSpacing) {
                    if menuBarIconStyle != "none" {
                        if menuBarIconStyle == "battery" { Image(systemName: "battery.100.bolt") }
                        else if menuBarIconStyle == "ios_native" { Image(systemName: "battery.75") }
                        else if menuBarIconStyle == "macos_color" { Image(systemName: "battery.100").foregroundColor(.green) }
                        else if menuBarIconStyle == "aldente_status" { Image(systemName: "minus.plus.batteryblock.fill") }
                        else if menuBarIconStyle == "aldente_icon" { Image(systemName: "leaf") }
                        else { Image(systemName: "battery.100") }
                    }
                    if showPercentage { Text("75%").font(.system(.body, design: .rounded).monospacedDigit()) }
                    if showChargingStatus { Image(systemName: "bolt.fill") }
                    if iconLowPowerColor { Circle().fill(Color.orange).frame(width: 8, height: 8) }
                    
                    if showMaxCapacity { HStack(spacing: 2) { Image(systemName: "stethoscope"); Text("100%") } }
                    if showMacOSCapacity { HStack(spacing: 2) { Image(systemName: "info.circle"); Text("100%") } }
                    if showMacOSCondition { HStack(spacing: 2) { Image(systemName: "cross.case"); Text("正常") } }
                    if showCycles { HStack(spacing: 2) { Image(systemName: "arrow.3.path"); Text("120") } }
                    
                    if showTemperature { HStack(spacing: 2) { Image(systemName: "thermometer"); Text("32°C") } }
                    if showTimeRemaining { HStack(spacing: 2) { Image(systemName: "clock"); Text("2:30") } }
                    if showAmperage { HStack(spacing: 2) { Image(systemName: "a.square"); Text("1.2A") } }
                    if showVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text("12.4V") } }
                    if showWattage { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text("15.2W") } }
                    if showSystemLoad { HStack(spacing: 2) { Image(systemName: "laptopcomputer"); Text("15.0W") } }
                    
                    if showAdapterCurrent { HStack(spacing: 2) { Image(systemName: "powerplug"); Text("2.0A") } }
                    if showAdapterVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text("20.0V") } }
                    if showAdapterPower { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text("40W") } }
                    
                    if showAlDenteCalibration { Image(systemName: "slider.vertical.3") }
                    if showAlDenteOverheat { Image(systemName: "flame") }
                    if showAlDenteSailing { Image(systemName: "paperplane") }
                    if showAlDenteFull { Image(systemName: "plus.circle") }
                }
                .font(.system(.body, design: .rounded).monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }
}

struct DashboardSettingsView: View {
    @State private var batteryData = BatteryData.empty
    
    // Simulate real-time updates for now
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Content: 2-Column Layout
                HStack(alignment: .top, spacing: 20) {
                    
                    // Left Column
                    VStack(spacing: 20) {
                        // 电池规格 Card
                        DashboardCard(title: "电池规格", icon: "bolt.fill", iconColor: .blue) {
                            VStack(spacing: 12) {
                                DataRow(label: "Current", value: String(format: "%.2f A", Double(batteryData.amperage) / 1000.0))
                                DataRow(label: "Voltage", value: String(format: "%.2f V", Double(batteryData.voltage) / 1000.0))
                                DataRow(label: "Power", value: String(format: "%.2f W", batteryData.adapter?.realTimeWatts ?? 0.0))
                                DataRow(label: "System Load", value: String(format: "%.2f W", abs(Double(batteryData.voltage) * Double(batteryData.amperage) / 1_000_000.0)))
                                DataRow(label: "Remaining Capacity", value: "\(batteryData.currentCapacity) mAh")
                            }
                        }
                        
                        // 电源适配器规格 Card
                        DashboardCard(title: "电源适配器规格", icon: "powerplug.fill", iconColor: .teal) {
                            VStack(spacing: 12) {
                                let maxC = batteryData.adapter?.activeProfile?.maxCurrent ?? 0
                                let maxV = batteryData.adapter?.activeProfile?.maxVoltage ?? 0
                                DataRow(label: "Adapter Name", value: batteryData.adapter?.name ?? "Unknown")
                                DataRow(label: "Design Power", value: "\(batteryData.adapterWatts) W")
                                DataRow(label: "Negotiated Current", value: String(format: "%.2f A", maxC))
                                DataRow(label: "Negotiated Voltage", value: String(format: "%.2f V", maxV))
                            }
                        }
                    }
                    
                    // Right Column
                    VStack(spacing: 20) {
                        // 电池健康 Card
                        DashboardCard(title: "电池健康", icon: "heart.fill", iconColor: .red) {
                            VStack(spacing: 12) {
                                DataRow(label: "Design Capacity", value: "\(batteryData.designCapacity) mAh")
                                DataRow(label: "Maximum Capacity", value: "\(batteryData.maxCapacity) mAh")
                                let healthPercent = batteryData.designCapacity > 0 ? (Double(batteryData.maxCapacity) / Double(batteryData.designCapacity)) * 100 : 0
                                DataRow(label: "macOS Status", value: healthPercent > 80 ? "Normal" : "Service Recommended")
                                DataRow(label: "Cycle Count", value: "\(batteryData.cycleCount)")
                            }
                        }
                    }
                }
                
                // Bottom Row: Small metrics widgets
                HStack(spacing: 20) {
                    DashboardSimpleCard(
                        title: "Battery Level", 
                        value: "\(batteryData.maxCapacity > 0 ? Int((Double(batteryData.currentCapacity) / Double(batteryData.maxCapacity)) * 100) : 0) %", 
                        icon: batteryData.maxCapacity > 0 ? "battery.100" : "battery.0",
                        iconColor: .green
                    )
                    DashboardSimpleCard(
                        title: "Battery Temperature", 
                        value: batteryData.temperature > 0 ? String(format: "%.1f°C", batteryData.temperature) : "--", 
                        icon: "thermometer",
                        iconColor: .orange
                    )
                    DashboardSimpleCard(
                        title: "Charging State", 
                        value: batteryData.isCharging ? "Charging" : "Discharging", 
                        icon: batteryData.isCharging ? "bolt.fill" : "battery.25",
                        iconColor: batteryData.isCharging ? .yellow : .blue
                    )
                }
            }
            .padding(32)
        }
        .navigationTitle("仪表盘")
        // In macOS 14+, using clear background with control opacity replicates the typical System Settings feel
        .background(VisualEffectBackground(material: .contentBackground, blendingMode: .withinWindow))
        .onAppear {
            self.batteryData = BatteryService.shared.fetchBatteryData()
        }
        .onReceive(timer) { _ in
            self.batteryData = BatteryService.shared.fetchBatteryData()
        }
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct DashboardSimpleCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Colored Icon Badge
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text Group
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .foregroundColor(.secondary)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    MainWindowView()
}

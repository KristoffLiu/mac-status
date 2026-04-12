import SwiftUI
import Combine

struct MainWindowView: View {
    @State private var selectedTab: MainWindowTab? = .dashboard
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    enum MainWindowTab: String, CaseIterable, Hashable {
        case dashboard = "Dashboard"
        case general = "General"
        case menuBar = "Menu Bar"
        case appearance = "Appearance"
        case about = "About"
        
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
    @AppStorage("menuRightClickAction") private var menuRightClickAction = "Same as Left Click"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // --- 顶部预览 ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "menubar.rectangle")
                        Text("Selected Menu Items")
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    VStack {
                        HStack(spacing: menuItemSpacing) {
                            if menuBarIconStyle == "battery" {
                                Image(systemName: "battery.100")
                                    .imageScale(.medium)
                            }
                            
                            if showPercentage {
                                Text("75%")
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                            
                            if showChargingStatus {
                                Image(systemName: "bolt.fill")
                            }
                            
                            if showCycles {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.3.path").font(.caption)
                                    Text("120")
                                }
                                .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                            
                            if showTemperature {
                                Text("32°C")
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                            
                            if showWattage {
                                Text("15.2W")
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                            
                            if showVoltage {
                                Text("12.4V")
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                            
                            if showAmperage {
                                Text("1.2A")
                                    .font(.system(.body, design: .rounded).monospacedDigit())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // --- 下方的项目卡片 ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book")
                        Text("Menu Item Directory")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 28) {
                        
                        MenuDirectoryRow(title: "Main Icon Style", subtitle: "(Select One)", showChevron: true) {
                            ChipButton(title: "Do Not Show", icon: "eye.slash", isSelected: menuBarIconStyle == "none") {
                                menuBarIconStyle = "none"
                            }
                            ChipButton(title: "AlDente Icon", icon: "leaf", isSelected: menuBarIconStyle == "aldente_icon") {
                                menuBarIconStyle = "aldente_icon"
                            }
                            ChipButton(title: "AlDente Status", icon: "battery.50", isSelected: menuBarIconStyle == "aldente_status") {
                                menuBarIconStyle = "aldente_status"
                            }
                            ChipButton(title: "macOS Native", icon: "battery.100.bolt", isSelected: menuBarIconStyle == "battery") {
                                menuBarIconStyle = "battery"
                            }
                            ChipButton(title: "macOS", icon: "battery.100", isSelected: menuBarIconStyle == "battery_plain") {
                                menuBarIconStyle = "battery_plain"
                            }
                        }
                        
                        MenuDirectoryRow(title: "Main Icon Options", showChevron: false) {
                            Toggle(isOn: $showPercentage) {
                                HStack(spacing: 4) {
                                    Image(systemName: "percent")
                                    Text("Show Percentage")
                                }
                            }
                            .toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $iconLowPowerColor) {
                                HStack(spacing: 4) {
                                    Image(systemName: "paintpalette.fill")
                                    Text("Low Power Mode Color")
                                }
                            }
                            .toggleStyle(ChipToggleStyle())
                        }
                        
                        MenuDirectoryRow(title: "Battery Health", showChevron: true) {
                            Toggle(isOn: $showMaxCapacity) {
                                HStack(spacing: 4) { Image(systemName: "stethoscope"); Text("Maximum Capacity") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showMacOSCapacity) {
                                HStack(spacing: 4) { Image(systemName: "info.circle"); Text("macOS Capacity") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showMacOSCondition) {
                                HStack(spacing: 4) { Image(systemName: "cross.case"); Text("macOS Condition") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showCycles) {
                                HStack(spacing: 4) { Image(systemName: "arrow.3.path"); Text("Cycles") }
                            }.toggleStyle(ChipToggleStyle())
                        }
                        
                        MenuDirectoryRow(title: "Battery Specs", showChevron: true) {
                            Toggle(isOn: $showTemperature) {
                                HStack(spacing: 4) { Image(systemName: "thermometer"); Text("Temperature") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showTimeRemaining) {
                                HStack(spacing: 4) { Image(systemName: "clock"); Text("Time until Full/Empty") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAmperage) {
                                HStack(spacing: 4) { Image(systemName: "battery.100"); Text("Current") } // matching their current
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showVoltage) {
                                HStack(spacing: 4) { Image(systemName: "v.square"); Text("Voltage") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showWattage) {
                                HStack(spacing: 4) { Image(systemName: "bolt.fill"); Text("Power") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showSystemLoad) {
                                HStack(spacing: 4) { Image(systemName: "laptopcomputer"); Text("System Load") }
                            }.toggleStyle(ChipToggleStyle())
                        }
                        
                        MenuDirectoryRow(title: "Power Adapter Specs", showChevron: false) {
                            Toggle(isOn: $showAdapterCurrent) {
                                HStack(spacing: 4) { Image(systemName: "powerplug"); Text("Current") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAdapterVoltage) {
                                HStack(spacing: 4) { Image(systemName: "v.square"); Text("Voltage") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAdapterPower) {
                                HStack(spacing: 4) { Image(systemName: "bolt.fill"); Text("Power") }
                            }.toggleStyle(ChipToggleStyle())
                        }
                        
                        MenuDirectoryRow(title: "AlDente Status", showChevron: true) {
                            Toggle(isOn: $showAlDenteCalibration) {
                                HStack(spacing: 4) { Image(systemName: "slider.vertical.3"); Text("Calibration Mode") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAlDenteOverheat) {
                                HStack(spacing: 4) { Image(systemName: "flame"); Text("Overheat Protection") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAlDenteSailing) {
                                HStack(spacing: 4) { Image(systemName: "paperplane"); Text("Sailing Mode") }
                            }.toggleStyle(ChipToggleStyle())
                            
                            Toggle(isOn: $showAlDenteFull) {
                                HStack(spacing: 4) { Image(systemName: "plus.circle"); Text("Fully Charged") }
                            }.toggleStyle(ChipToggleStyle())
                        }
                        
                        Divider().padding(.top, 8)
                        
                        // 重置按钮区域
                        HStack(spacing: 12) {
                            Spacer()
                            Button(action: {
                                // reset all
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                // clear all
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
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Clear All")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.windowBackgroundColor))
                                .foregroundColor(.red)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // --- 间距与额外设置 ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "menubar.rectangle")
                            .frame(width: 20)
                        Text("Menu Item Spacing")
                            .font(.system(.body, weight: .medium))
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(menuItemSpacing))")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        Slider(value: $menuItemSpacing, in: 0...20, step: 1)
                            .frame(width: 150)
                        Text("20")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 20)
                        Text("Menu Update Interval")
                            .font(.system(.body, weight: .medium))
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(menuUpdateInterval))")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)
                        Slider(value: $menuUpdateInterval, in: 2...20, step: 1)
                            .frame(width: 150)
                        Text("20")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "square.topthird.inset.filled")
                            .frame(width: 20)
                        Text("Menu Bar Right Click")
                            .font(.system(.body, weight: .medium))
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $menuRightClickAction) {
                            Text("Same as Left Click").tag("Same as Left Click")
                            Text("Quit").tag("Quit")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Menu Bar Properties")
    }
}

// A helper for rows in Menu Item Directory:
struct MenuDirectoryRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let showChevron: Bool
    
    init(title: String, subtitle: String? = nil, showChevron: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).font(.headline).fontWeight(.semibold)
                if let sub = subtitle {
                    Text(sub).font(.subheadline).foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        content
                    }
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
        }
    }
}

// MARK: - Toggle Styles & Buttons

struct ChipToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.label
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundColor(configuration.isOn ? .white : .primary)
        .background(configuration.isOn ? Color.accentColor : Color.clear)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(configuration.isOn ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

struct ChipButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundColor(isSelected ? .white : .primary)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

struct DashboardSettingsView: View {
    @State private var batteryData = BatteryData.empty
    
    // Simulate real-time updates for now
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 350), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Battery Specs Card
                    DashboardCard(title: "Battery Specs", icon: "bolt.fill", iconColor: .primary) {
                        VStack(spacing: 8) {
                            DataRow(label: "Current", value: String(format: "%.2f A", Double(batteryData.amperage) / 1000.0))
                            DataRow(label: "Voltage", value: String(format: "%.2f V", Double(batteryData.voltage) / 1000.0))
                            DataRow(label: "Power", value: String(format: "%.2f W", batteryData.adapter?.realTimeWatts ?? 0))
                            DataRow(label: "System Load", value: String(format: "%.2f W", abs(Double(batteryData.voltage) * Double(batteryData.amperage) / 1_000_000.0)))
                            DataRow(label: "Remaining Capacity", value: "\(batteryData.currentCapacity) mAh")
                        }
                    }
                    
                    // Battery Health Card
                    DashboardCard(title: "Battery Health", icon: "heart.fill", iconColor: .primary) {
                        VStack(spacing: 8) {
                            DataRow(label: "Design Capacity", value: "\(batteryData.designCapacity) mAh")
                            DataRow(label: "Maximum Capacity", value: "\(batteryData.maxCapacity) mAh")
                            let healthPercent = batteryData.designCapacity > 0 ? (Double(batteryData.maxCapacity) / Double(batteryData.designCapacity)) * 100 : 0
                            DataRow(label: "macOS Status", value: healthPercent > 80 ? "Normal" : "Service Recommended")
                            DataRow(label: "Cycle Count", value: "\(batteryData.cycleCount)")
                        }
                    }
                    
                    // Power Adapter Setup Card
                    DashboardCard(title: "Power Adapter Specs", icon: "powerplug.fill", iconColor: .primary) {
                        VStack(spacing: 8) {
                            let maxC = batteryData.adapter?.activeProfile?.maxCurrent ?? 0
                            let maxV = batteryData.adapter?.activeProfile?.maxVoltage ?? 0
                            DataRow(label: "Adapter Name", value: batteryData.adapter?.name ?? "Unknown")
                            DataRow(label: "Design Power", value: "\(batteryData.adapterWatts) W")
                            DataRow(label: "Negotiated Current", value: String(format: "%.2f A", maxC))
                            DataRow(label: "Negotiated Voltage", value: String(format: "%.2f V", maxV))
                        }
                    }
                }
                
                // Additional Info row
                HStack(spacing: 16) {
                    DashboardSimpleCard(title: "Battery Level", value: "\(batteryData.maxCapacity > 0 ? Int((Double(batteryData.currentCapacity) / Double(batteryData.maxCapacity)) * 100) : 0) %", icon: "battery.100")
                    DashboardSimpleCard(title: "Battery Temperature", value: batteryData.temperature > 0 ? String(format: "%.1f°C", batteryData.temperature) : "--", icon: "thermometer")
                    DashboardSimpleCard(title: "Charging State", value: batteryData.isCharging ? "Charging" : "Discharging", icon: batteryData.isCharging ? "bolt.fill" : "battery.50")
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(LocalizedStringKey(title))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(NSColor.textBackgroundColor).opacity(0.6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DashboardSimpleCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.textBackgroundColor).opacity(0.6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MainWindowView()
}

import SwiftUI

struct MenuBarSettingsView: View {
    // 主图标原子选项 (Atomic Options)
    @AppStorage(AppPreferenceKeys.batteryShellStyle) private var batteryShellStyle = "native"
    @AppStorage(AppPreferenceKeys.batteryFillStyle) private var batteryFillStyle = "monochrome"
    @AppStorage(AppPreferenceKeys.batteryInnerContent) private var batteryInnerContent = "none"
    @AppStorage(AppPreferenceKeys.batteryChargingIndicator) private var batteryChargingIndicator = "bolt"
    @AppStorage(AppPreferenceKeys.batteryLayout) private var batteryLayout = "left"
    
    @AppStorage(AppPreferenceKeys.showPercentage) private var showPercentage = true
    @AppStorage(AppPreferenceKeys.showChargingStatus) private var showChargingStatus = false
    
    // 主图标选项
    @AppStorage(AppPreferenceKeys.iconLowPowerColor) private var iconLowPowerColor = false
    
    // 电池健康
    @AppStorage(AppPreferenceKeys.showMaxCapacity) private var showMaxCapacity = false
    @AppStorage(AppPreferenceKeys.showMacOSCapacity) private var showMacOSCapacity = false
    @AppStorage(AppPreferenceKeys.showMacOSCondition) private var showMacOSCondition = false
    @AppStorage(AppPreferenceKeys.showCycles) private var showCycles = false
    
    // 预览外观
    @AppStorage(AppPreferenceKeys.previewIsDark) private var previewIsDark = true
    
    // 电池规格
    @AppStorage(AppPreferenceKeys.showTemperature) private var showTemperature = false
    @AppStorage(AppPreferenceKeys.showTimeRemaining) private var showTimeRemaining = false
    @AppStorage(AppPreferenceKeys.showAmperage) private var showAmperage = false
    @AppStorage(AppPreferenceKeys.showVoltage) private var showVoltage = false
    @AppStorage(AppPreferenceKeys.showWattage) private var showWattage = false
    @AppStorage(AppPreferenceKeys.showSystemLoad) private var showSystemLoad = false
    
    // 电源适配器规格
    @AppStorage(AppPreferenceKeys.showAdapterCurrent) private var showAdapterCurrent = false
    @AppStorage(AppPreferenceKeys.showAdapterVoltage) private var showAdapterVoltage = false
    @AppStorage(AppPreferenceKeys.showAdapterPower) private var showAdapterPower = false
    
    // AlDente 状态
    @AppStorage(AppPreferenceKeys.showAlDenteCalibration) private var showAlDenteCalibration = false
    @AppStorage(AppPreferenceKeys.showAlDenteOverheat) private var showAlDenteOverheat = false
    @AppStorage(AppPreferenceKeys.showAlDenteSailing) private var showAlDenteSailing = false
    @AppStorage(AppPreferenceKeys.showAlDenteFull) private var showAlDenteFull = false
    
    // 底部参数
    @AppStorage(AppPreferenceKeys.menuItemSpacing) private var menuItemSpacing: Double = 4
    @AppStorage(AppPreferenceKeys.menuUpdateInterval) private var menuUpdateInterval: Double = 10
    @AppStorage(AppPreferenceKeys.menuRightClickAction) private var menuRightClickAction: MenuBarRightClickAction = .sameAsLeft

    @AppStorage(AppPreferenceKeys.mainIconGroupSpacing) private var mainIconGroupSpacing: Double = 4

    // 弹出状态
    @State private var isShowingBatteryConfig = false
    
    var body: some View {
        Form {
            previewSection
            
            Section {
                HStack {
                    Label("电池图标", systemImage: "battery.100")
                    Spacer()
                    Button("电池图标 选项...") {
                        isShowingBatteryConfig = true
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("图形定制")
            } footer: {
                Text("配置电池图标外观与显示风格。")
            }
            .sheet(isPresented: $isShowingBatteryConfig) {
                MenuBarBatteryConfigView()
            }
            
            Section("附加显示 (图标组外部)") {
                Toggle("外置显式百分比", isOn: $showPercentage)
                Toggle("外置显式充电状态", isOn: $showChargingStatus)
                
                Picker("图形所在位置", selection: $batteryLayout) {
                    Text("左侧").tag("left")
                    Text("右侧").tag("right")
                }
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
                Text("尚未接入 AlDente 状态数据")
                    .font(.caption).foregroundStyle(.secondary)
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
                    Text("同左击").tag(MenuBarRightClickAction.sameAsLeft)
                    Text("退出应用").tag(MenuBarRightClickAction.quit)
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("重置所有设置") {
                        AppPreferences.resetMenuBar()
                    }
                    .buttonStyle(.borderless)
                    
                    Button("清空显示项") {
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
        .navigationTitle("菜单栏")
    }

    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "menubar.rectangle")
                        .foregroundColor(.blue)
                    Text("实时显示效果")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(previewIsDark ? .white : .primary)
                    Spacer()
                    
                    Button(action: { previewIsDark.toggle() }) {
                        Image(systemName: previewIsDark ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(previewIsDark ? .yellow : .orange)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
                
                // Using a light-weight preview with real current storage values
                UnifiedPreviewRow()
            }
            .padding(.vertical, 8)
        }
    }
}

// Simplified Preview for the main settings page
struct UnifiedPreviewRow: View {
    @AppStorage(AppPreferenceKeys.menuBarPowerStyle) private var menuBarPowerStyle: MenuBarPowerStyle = .graphic
    @AppStorage(AppPreferenceKeys.previewIsDark) private var previewIsDark = true
    @AppStorage(AppPreferenceKeys.batteryShellStyle) private var batteryShellStyle = "native"
    @AppStorage(AppPreferenceKeys.batteryFillStyle) private var batteryFillStyle = "monochrome"
    @AppStorage(AppPreferenceKeys.batteryInnerContent) private var batteryInnerContent = "none"
    @AppStorage(AppPreferenceKeys.batteryChargingIndicator) private var batteryChargingIndicator = "bolt"
    @AppStorage(AppPreferenceKeys.batteryChargingBorderStyle) private var batteryChargingBorderStyle = "sharp"

    // We use actual data from the shared service or a static mock for the main page
    @ObservedObject private var viewModel = StatusViewModel.shared

    var body: some View {
        let batteryView = BatteryGraphicView(
            capacity: viewModel.currentCapacity,
            isCharging: viewModel.isCharging,
            isPowered: viewModel.powerFlow.hasAdapter,
            isColored: batteryFillStyle == "status_color",
            chargingStyle: batteryChargingIndicator,
            showNumber: batteryInnerContent == "inside",
            isIOSStyle: batteryShellStyle == "ios",
            borderStyle: batteryChargingBorderStyle
        )
        
        let batteryImage: NSImage? = {
            if menuBarPowerStyle != .graphic || batteryShellStyle == "hidden" { return nil }
            let renderer = ImageRenderer(content: batteryView.environment(\.colorScheme, previewIsDark ? .dark : .light).padding(1))
            renderer.scale = 2.0
            if let img = renderer.nsImage {
                img.isTemplate = batteryFillStyle == "monochrome"
                return img
            }
            return nil
        }()
        
        MenuBarLabelRendererView(viewModel: viewModel, generatedMenuImage: batteryImage)
            .environment(\.colorScheme, previewIsDark ? .dark : .light)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(previewIsDark ? Color.black : Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
}

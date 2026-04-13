import SwiftUI

struct MenuBarSettingsView: View {
    // 主图标原子选项 (Atomic Options)
    @AppStorage("batteryShellStyle") private var batteryShellStyle = "native"
    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryInnerContent") private var batteryInnerContent = "bolt"
    @AppStorage("batteryLayout") private var batteryLayout = "left"
    
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

    @AppStorage("mainIconGroupSpacing") private var mainIconGroupSpacing: Double = 4

    var body: some View {
        Form {
            Section("电池图形定制") {
                Picker("外壳形状", selection: $batteryShellStyle) {
                    Text("经典原生").tag("native")
                    Text("紧凑填充").tag("ios")
                    Text("隐藏不显示").tag("hidden")
                }
                .pickerStyle(.segmented)
                
                Picker("色彩基调", selection: $batteryFillStyle) {
                    Text("系统单色").tag("monochrome")
                    Text("彩色生命条").tag("status_color")
                }
                .pickerStyle(.segmented)

                Picker("内部显示物", selection: $batteryInnerContent) {
                    Text("空").tag("none")
                    Text("充电闪电").tag("bolt")
                    Text("电量数字").tag("number")
                }
                .pickerStyle(.segmented)
            }
            
            Section("图形与附加文字布局") {
                Picker("图形所在位置", selection: $batteryLayout) {
                    Text("组件最左").tag("left")
                    Text("组件最右").tag("right")
                }
                .pickerStyle(.segmented)
            }

            Section("附加显示 (图标组外部)") {
                Toggle("外置显式百分比", isOn: $showPercentage)
                Toggle("极低电量变色提醒", isOn: $iconLowPowerColor)
                Toggle("外置显式充电状态", isOn: $showChargingStatus)
                
                HStack {
                    Text("图标组内间距")
                    Slider(value: $mainIconGroupSpacing, in: 0...10, step: 1)
                    Text("\(Int(mainIconGroupSpacing))")
                        .monospacedDigit()
                        .frame(width: 24, alignment: .trailing)
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
                        mainIconGroupSpacing = 4
                        menuUpdateInterval = 2
                    }
                    .buttonStyle(.borderless)
                    
                    Button("全部清除") {
                        batteryShellStyle = "hidden"
                        batteryFillStyle = "monochrome"
                        batteryInnerContent = "none"
                        batteryLayout = "left"
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
                    HStack(spacing: mainIconGroupSpacing) {
                        let innerPreview = Group {
                            BatteryGraphicView(
                                capacity: 75,
                                isCharging: true,
                                isColored: batteryFillStyle == "status_color",
                                showBolt: batteryInnerContent == "bolt" || batteryInnerContent == "number",
                                showNumber: batteryInnerContent == "number",
                                isIOSStyle: batteryShellStyle == "ios"
                            )
                        }
                        
                        if batteryLayout == "left" { innerPreview }
                        
                        if showPercentage { Text("75%") }
                        if showChargingStatus { Image(systemName: "bolt.fill") }
                        if iconLowPowerColor { Circle().fill(Color.orange).frame(width: 8, height: 8) }
                        
                        if batteryLayout == "right" { innerPreview }
                    }
                    
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

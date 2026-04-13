import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var widgetManager = WidgetManager.shared
    @AppStorage("isPanelEditing") private var isPanelEditing = false
    
    @AppStorage("autoHidePanel") private var autoHidePanel = true
    @AppStorage("enablePanelAnimations") private var enablePanelAnimations = true
    @AppStorage("panelTheme") private var panelTheme = "system"
    
    var body: some View {
        Form {
            Section("全局面板行为") {
                Toggle("失去焦点时自动隐藏", isOn: $autoHidePanel)
                Toggle("平滑弹出动画", isOn: $enablePanelAnimations)
                Picker("面板主题", selection: $panelTheme) {
                    Text("跟随系统").tag("system")
                    Text("始终浅色").tag("light")
                    Text("始终深色").tag("dark")
                }
            }
            
            Section {
                List {
                    ForEach(widgetManager.activeWidgets, id: \.self) { widget in
                        WidgetRowView(widget: widget, isActive: true)
                    }
                    .onMove(perform: widgetManager.move)
                    
                    ForEach(widgetManager.inactiveWidgets, id: \.self) { widget in
                        WidgetRowView(widget: widget, isActive: false)
                    }
                }
                .frame(minHeight: 300)
            } header: {
                HStack {
                    Text("面板控制")
                    Spacer()
                    Button("呼出面板进行交互排布...") {
                        isPanelEditing = true
                        openMenuBarPanel()
                    }
                }
            } footer: {
                Text("可将系统模块控制配置为在面板中显示。拖拽可以进行排序。")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("菜单栏与面板")
    }
    
    private func openMenuBarPanel() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenMenuBarPopover"), object: nil)
    }
}

struct WidgetRowView: View {
    let widget: PanelWidget
    var isActive: Bool
    @StateObject private var widgetManager = WidgetManager.shared
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { isActive },
                set: { newValue in
                    withAnimation {
                        if newValue {
                            widgetManager.add(widget)
                        } else {
                            widgetManager.remove(widget)
                        }
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(widget.iconColor.opacity(0.2))
                Image(systemName: widget.icon)
                    .foregroundColor(widget.iconColor)
            }
            .frame(width: 24, height: 24)
            
            Text(LocalizedStringKey(widget.title))
            
            Spacer()
            
            Button {
                showingOptions = true
            } label: {
                Text("\(widget.title) 选项...")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingOptions) {
            WidgetOptionsSheet(widget: widget)
        }
    }
}

struct WidgetOptionsSheet: View {
    let widget: PanelWidget
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if widget == .systemMonitor {
                SystemMonitorConfigView()
            } else {
                VStack(spacing: 0) {
                    if widget == .powerFlow {
                        PowerFlowConfigView()
                    } else {
                        Form {
                            Text("暂无可用的自定义选项。")
                                .foregroundColor(.secondary)
                        }
                        .formStyle(.grouped)
                        .frame(width: 380)
                    }
                    
                    HStack {
                        Spacer()
                        Button("完成") {
                            dismiss()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding()
                }
                .background(Color(NSColor.underPageBackgroundColor))
                .frame(minHeight: 200)
            }
        }
    }
}

struct SystemMonitorConfigView: View {
    @AppStorage("sysMonShowCompute") private var showCompute = true
    @AppStorage("sysMonShowMemory") private var showMemory = true
    @AppStorage("sysMonShowNetDisk") private var showNetDisk = true
    @AppStorage("sysMonSymmetricGraph") private var symmetricGraph = false
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：独立的侧边栏式预览
            VStack {
                SystemMonitorModule()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                Spacer()
            }
            .padding(20)
            .frame(width: 320)
            .frame(maxHeight: .infinity)
            
            Divider()
            
            // 右侧：偏好设置详情
            VStack(spacing: 0) {
                Form {
                    Section("显示模块") {
                        Toggle("计算 (CPU 与 GPU)", isOn: $showCompute)
                        Toggle("统一内存", isOn: $showMemory)
                        Toggle("网络与磁盘", isOn: $showNetDisk)
                    }
                    
                    Section("图表样式 (网络与磁盘)") {
                        Picker("走势图方向", selection: $symmetricGraph) {
                            Text("正向堆叠").tag(false)
                            Text("双向发散").tag(true)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("全局图表渲染") {
                        Picker("像素阵列间距", selection: $pixelGap) {
                            Text("紧密集约 (1.0)").tag(1.0)
                            Text("标准 (1.5)").tag(1.5)
                            Text("呼吸松散 (2.5)").tag(2.5)
                        }
                        .pickerStyle(.menu)
                    }
                }
                .formStyle(.grouped)
                
                HStack {
                    Spacer()
                    Button("完成") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .frame(width: 360)
            .frame(maxHeight: .infinity)
        }
        .frame(height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PowerFlowConfigView: View {
    @AppStorage("powerFlowStyle") private var style: PowerFlowStyle = .sankey
    @AppStorage("powerFlowSankeyAnimated") private var isAnimated = true
    @AppStorage("powerFlowSankeyShowValues") private var showValues = true
    
    @State private var simSystemPower: Double = 25.0
    @State private var simAdapterPower: Double = 65.0
    @State private var simIsBatteryFull: Bool = false
    @State private var isSimulatorExpanded: Bool = false
    
    var currentPreviewData: PowerFlowData {
        var effectiveAdapterPower = simAdapterPower
        
        if simIsBatteryFull && effectiveAdapterPower > simSystemPower {
            effectiveAdapterPower = simSystemPower
        }
        
        let diff = effectiveAdapterPower - simSystemPower
        let batteryWatts = abs(diff)
        
        if effectiveAdapterPower < 0.1 {
            // 纯电池供电
            return PowerFlowData(adapterPower: 0, batteryPower: simSystemPower, systemPower: simSystemPower, isCharging: false, isDischarging: true, topology: .topologyB, adapterVoltage: nil, adapterCurrent: nil)
        } else if effectiveAdapterPower >= simSystemPower {
            // 适配器供电充足：旁路 + 充电(或闲置)
            let isCharging = !simIsBatteryFull && batteryWatts > 0.1
            return PowerFlowData(adapterPower: effectiveAdapterPower, batteryPower: batteryWatts, systemPower: simSystemPower, isCharging: isCharging, isDischarging: false, topology: .topologyA, adapterVoltage: 20.0, adapterCurrent: effectiveAdapterPower / 20.0)
        } else {
            // 供电不足：电池与适配器混合供电
            return PowerFlowData(adapterPower: effectiveAdapterPower, batteryPower: batteryWatts, systemPower: simSystemPower, isCharging: false, isDischarging: true, topology: .topologyB, adapterVoltage: 20.0, adapterCurrent: effectiveAdapterPower / 20.0)
        }
    }
    
    var body: some View {
        Form {
            // 1. 预览区域与调节
            Section {
                VStack(spacing: 0) {
                    PowerFlowModuleView(powerFlow: currentPreviewData)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                .frame(width: 400)
                .background(.regularMaterial)
                .cornerRadius(12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Label("预览调节", systemImage: "slider.horizontal.3")
                    Spacer()
                    Button("设置电源参数...") {
                        isSimulatorExpanded.toggle()
                    }
                    .popover(isPresented: $isSimulatorExpanded, arrowEdge: .trailing) {
                        simulatorPanelView()
                    }
                }
                .padding(.vertical, 2)
            }
            
            // 3. 视图选择
            Section("显示样式") {
                Picker("样式", selection: $style) {
                    Text("桑基图 (Sankey)").tag(PowerFlowStyle.sankey)
                    Text("数据块 (Blocks)").tag(PowerFlowStyle.blocks)
                }
                .pickerStyle(.segmented)
            }
            
            // 4. 桑基图设置
            if style == .sankey {
                Section("桑基图微调") {
                    Toggle("播放流动动画", isOn: $isAnimated)
                    Toggle("在管道上显示具体瓦数", isOn: $showValues)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    @ViewBuilder
    private func simulatorPanelView() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("系统消耗")
                    .frame(width: 80, alignment: .leading)
                Slider(value: $simSystemPower, in: 2.0...120.0)
                Text("\(Int(simSystemPower)) W")
                    .frame(width: 45, alignment: .trailing)
                    .monospacedDigit()
            }
            
            HStack {
                Text("适配器输入")
                    .frame(width: 80, alignment: .leading)
                Slider(value: $simAdapterPower, in: 0.0...140.0)
                Text("\(Int(simAdapterPower)) W")
                    .frame(width: 45, alignment: .trailing)
                    .monospacedDigit()
            }
            
            Toggle("电池已满电自动拒充", isOn: $simIsBatteryFull)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            
            let effectiveAdapterPower = (simIsBatteryFull && simAdapterPower > simSystemPower) ? simSystemPower : simAdapterPower
            let batDiff = effectiveAdapterPower - simSystemPower
            let batLabel = batDiff > 0.1 ? "电池充电" : (batDiff < -0.1 ? "电池输出" : "电池闲置")
            
            HStack {
                Text(batLabel)
                    .frame(width: 80, alignment: .leading)
                Spacer()
                Text("\(Int(abs(batDiff))) W")
                    .frame(width: 45, alignment: .trailing)
                    .monospacedDigit()
            }
            .foregroundColor(abs(batDiff) > 0.1 ? .secondary : .secondary.opacity(0.5))
        }
        .padding()
        .frame(width: 320)
    }
}

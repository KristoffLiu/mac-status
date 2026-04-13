import SwiftUI

enum PowerFlowStyle: String, CaseIterable {
    case sankey = "sankey"
    case cards = "cards"
    case blocks = "blocks"
    case twin = "twin"
}

struct PowerFlowModuleView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    @AppStorage("powerFlowStyle") private var style: PowerFlowStyle = .cards
    
    var body: some View {
        switch style {
        case .sankey:
            SankeyPowerFlowView(powerFlow: powerFlow)
        case .cards:
            CardsPowerFlowView(powerFlow: powerFlow, batteryData: batteryData)
        case .blocks:
            BlockPowerFlowView(powerFlow: powerFlow)
        case .twin:
            DigitalTwinPowerFlowView(powerFlow: powerFlow, batteryData: batteryData)
        }
    }
}

// MARK: - Plugin Definition
struct PowerFlowPlugin: AppWidgetPlugin {
    let id = "powerFlow"
    let name = "实时能耗流"
    let icon = "bolt.horizontal"
    let hasSettings = true
    
    var wantsEdgeToEdge: Bool {
        @AppStorage("powerFlowStyle") var style = PowerFlowStyle.sankey
        return style == .cards
    }
    
    @MainActor
    var contentView: AnyView {
        AnyView(PowerFlowPluginContentView())
    }
    
    @MainActor
    var settingsView: AnyView {
        AnyView(PowerFlowConfigView())
    }
}

private struct PowerFlowPluginContentView: View {
    @EnvironmentObject var viewModel: StatusViewModel
    
    var body: some View {
        PowerFlowModuleView(powerFlow: viewModel.powerFlow, batteryData: viewModel.batteryData)
    }
}

struct PowerFlowConfigView: View {
    @AppStorage("powerFlowStyle") private var style: PowerFlowStyle = .sankey
    @AppStorage("powerFlowSankeyAnimated") private var isAnimated = true
    @AppStorage("powerFlowTwinAnimated") private var isTwinAnimated = true
    @AppStorage("powerFlowSankeyShowValues") private var showValues = true
    @Environment(\.dismiss) var dismiss
    
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
    
    var currentPreviewBatteryData: BatteryData {
        var data = BatteryData.empty
        data.currentCapacity = 80
        data.voltage = 11400
        data.amperage = 1500
        data.adapter = AdapterInfo(id: 1, familyCode: 1, name: "Simulation Adapter", designWatts: 140, realTimeWatts: simAdapterPower, activeProfileIndex: 1, profiles: [], current: 3.25, voltage: 20.0, watts: simAdapterPower)
        return data
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                // 1. 预览区域与调节
                Section {
                    VStack(spacing: 0) {
                        PowerFlowModuleView(powerFlow: currentPreviewData, batteryData: currentPreviewBatteryData)
                            .padding(.horizontal, style == .cards ? -12 : 4)
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
                    HStack(spacing: 12) {
                        StyleSelectButton(title: "数字孪生", icon: "cube.transparent", style: .twin, currentSelection: $style)
                        StyleSelectButton(title: "桑基图", icon: "water.waves", style: .sankey, currentSelection: $style)
                        StyleSelectButton(title: "数据块", icon: "square.grid.2x2", style: .blocks, currentSelection: $style)
                        StyleSelectButton(title: "卡片", icon: "rectangle.grid.1x2.fill", style: .cards, currentSelection: $style)
                    }
                    .padding(.vertical, 4)
                }
                
                // 4. 桑基图设置
                if style == .sankey {
                    Section("桑基图微调") {
                        Toggle("播放流动动画", isOn: $isAnimated)
                        Toggle("在管道上显示具体瓦数", isOn: $showValues)
                    }
                } else if style == .twin {
                    Section("数字孪生微调") {
                        Toggle("播放流动动画", isOn: $isTwinAnimated)
                    }
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
        .frame(minHeight: 200)
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

struct StyleSelectButton: View {
    let title: String
    let icon: String
    let style: PowerFlowStyle
    @Binding var currentSelection: PowerFlowStyle
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentSelection = style
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(currentSelection == style ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            .foregroundColor(currentSelection == style ? .accentColor : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(currentSelection == style ? Color.accentColor.opacity(0.8) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

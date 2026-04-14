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
    @AppStorage("powerFlowThreeStage") private var isThreeStage = false
    @AppStorage("powerFlowTwinAnimated") private var isTwinAnimated = true
    @AppStorage("twinCableStyle") private var twinCableStyle: String = "p"
    @AppStorage("twinMacColor") private var twinMacColor: String = "silver"
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
        
        var isCharging = false
        var isDischarging = false
        var topology: TopologyState = .topologyB
        
        if effectiveAdapterPower < 0.1 {
            // 纯电池供电
            isDischarging = true
            topology = .topologyB
        } else if effectiveAdapterPower >= simSystemPower {
            // 适配器供电充足：旁路 + 充电(或闲置)
            isCharging = !simIsBatteryFull && batteryWatts > 0.1
            topology = .topologyA
        } else {
            // 供电不足：电池与适配器混合供电
            isDischarging = true
            topology = .topologyB
        }
        
        let coreW = simSystemPower * 0.4
        let appW = simSystemPower * 0.35
        let periW = simSystemPower - coreW - appW
        
        return PowerFlowData(
            adapterPower: effectiveAdapterPower,
            batteryPower: batteryWatts,
            systemPower: simSystemPower,
            isCharging: isCharging,
            isDischarging: isDischarging,
            topology: topology,
            adapterVoltage: effectiveAdapterPower > 0 ? 20.0 : nil,
            adapterCurrent: effectiveAdapterPower > 0 ? (effectiveAdapterPower / 20.0) : nil,
            coreWatts: isThreeStage ? coreW : nil,
            peripheralWatts: isThreeStage ? periW : nil,
            topAppWatts: isThreeStage ? appW : nil,
            topAppName: isThreeStage ? "Xcode" : nil
        )
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
                            .padding(.horizontal, style == .cards ? 0 : 4)
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
                Section {
                    HStack(alignment: .top) {
                        Text("显示样式")
                            .padding(.top, 6)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            StyleSelectButton(title: "数字孪生", style: .twin, currentSelection: $style) {
                                TwinSkeleton()
                            }
                            StyleSelectButton(title: "桑基图", style: .sankey, currentSelection: $style) {
                                SankeySkeleton()
                            }
                            StyleSelectButton(title: "数据块", style: .blocks, currentSelection: $style) {
                                BlocksSkeleton()
                            }
                            StyleSelectButton(title: "卡片", style: .cards, currentSelection: $style) {
                                CardsSkeleton()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // 4. 桑基图设置
                if style == .sankey {
                    Section("桑基图微调") {
                        Toggle("展开系统耗电拆解 (三段式)", isOn: $isThreeStage)
                        Toggle("播放流动动画", isOn: $isAnimated)
                        Toggle("在管道上显示具体瓦数", isOn: $showValues)
                    }
                } else if style == .twin {
                    Section("数字孪生微调") {
                        Toggle("播放流动动画", isOn: $isTwinAnimated)
                        
                        Picker("理线风格", selection: $twinCableStyle) {
                            Text("随性自然 (P人)").tag("p")
                            Text("横平竖直 (J人)").tag("j")
                        }
                        
                        Picker("Mac 外观", selection: $twinMacColor) {
                            Text("银色").tag("silver")
                            Text("深空灰").tag("spaceGray")
                            Text("午夜色").tag("midnight")
                            Text("星光色").tag("starlight")
                        }
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

struct StyleSelectButton<Content: View>: View {
    let title: String
    let style: PowerFlowStyle
    @Binding var currentSelection: PowerFlowStyle
    @ViewBuilder let content: Content
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentSelection = style
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                    
                    content
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: 72, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .padding(3) // 留白：给选中框和图标之间的间距
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(currentSelection == style ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                
                Text(title)
                    .font(.system(size: 11, weight: currentSelection == style ? .semibold : .medium))
                    .foregroundColor(currentSelection == style ? .primary : .secondary)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Skeleton Drawings
struct TwinSkeleton: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white).frame(width: 12, height: 12)
                Rectangle().fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)).frame(width: 16, height: 2)
                VStack(spacing: 1.5) {
                    RoundedRectangle(cornerRadius: 1.5).fill(Color(white: 0.8)).frame(width: 18, height: 12)
                    RoundedRectangle(cornerRadius: 0.5).fill(Color(white: 0.5)).frame(width: 20, height: 2)
                }
            }
        }
    }
}

struct SankeySkeleton: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Path { path in
                path.move(to: CGPoint(x: -5, y: 12))
                path.addCurve(to: CGPoint(x: 77, y: 34), control1: CGPoint(x: 35, y: 12), control2: CGPoint(x: 35, y: 34))
            }
            .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            Path { path in
                path.move(to: CGPoint(x: -5, y: 36))
                path.addCurve(to: CGPoint(x: 77, y: 16), control1: CGPoint(x: 35, y: 36), control2: CGPoint(x: 35, y: 16))
            }
            .stroke(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        }
    }
}

struct BlocksSkeleton: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 4) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)).frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 3).fill(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)).frame(width: 22, height: 12)
                }
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)).frame(width: 22, height: 12)
                    RoundedRectangle(cornerRadius: 3).fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)).frame(width: 22, height: 22)
                }
            }
        }
    }
}

struct CardsSkeleton: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 5) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: 14, height: 10)
                    RoundedRectangle(cornerRadius: 3).fill(Color(white: 0.25)).frame(width: 32, height: 10)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.green).frame(width: 14, height: 10)
                    RoundedRectangle(cornerRadius: 3).fill(Color(white: 0.25)).frame(width: 32, height: 10)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.orange).frame(width: 14, height: 10)
                    RoundedRectangle(cornerRadius: 3).fill(Color(white: 0.25)).frame(width: 32, height: 10)
                }
            }
        }
    }
}

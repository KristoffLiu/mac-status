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
    @AppStorage("powerFlowSankeyStyle") private var sankeyStyle = "watchband"
    @AppStorage("powerFlowTwinAnimated") private var isTwinAnimated = true
    @AppStorage("twinDeviceType") private var twinDeviceType: String = "mbp"
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
                            StyleSelectButton(title: "数字孪生", value: .twin, currentSelection: $style) {
                                TwinSkeleton()
                            }
                            StyleSelectButton(title: "桑基图", value: .sankey, currentSelection: $style) {
                                SankeySkeleton()
                            }
                            StyleSelectButton(title: "数据块", value: .blocks, currentSelection: $style) {
                                BlocksSkeleton()
                            }
                            StyleSelectButton(title: "卡片", value: .cards, currentSelection: $style) {
                                CardsSkeleton()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // 4. 桑基图设置
                if style == .sankey {
                    Section("管线外观") {
                        HStack(alignment: .top) {
                            Text("管线风格")
                                .padding(.top, 6)
                            Spacer()
                            HStack(spacing: 12) {
                                WideOptionSelectButton(title: "标准", value: "standard", currentSelection: $sankeyStyle) { SankeyStyleSkeletonStandard() }
                                WideOptionSelectButton(title: "Apple Watch 表带", value: "watchband", currentSelection: $sankeyStyle) { SankeyStyleSkeletonWatchBand() }
                            }
                        }
                        .padding(.vertical, 2)
                        
                        Toggle("三段视图", isOn: $isThreeStage)
                        Toggle("播放流动动画", isOn: $isAnimated)
                        Toggle("在管道上显示具体瓦数", isOn: $showValues)
                    }
                } else if style == .twin {
                    Section("硬件外观") {
                        HStack(alignment: .top) {
                            Text("设备型号")
                                .padding(.top, 6)
                            Spacer()
                            HStack(spacing: 8) {
                                OptionSelectButton(title: "MBP", value: "mbp", currentSelection: $twinDeviceType) { TwinSkeletonMBP() }
                                OptionSelectButton(title: "Air", value: "mba", currentSelection: $twinDeviceType) { TwinSkeletonMBA() }
                                OptionSelectButton(title: "Mini", value: "mini", currentSelection: $twinDeviceType) { TwinSkeletonMini() }
                                OptionSelectButton(title: "Studio", value: "studio", currentSelection: $twinDeviceType) { TwinSkeletonStudio() }
                                OptionSelectButton(title: "iMac", value: "imac", currentSelection: $twinDeviceType) { TwinSkeletoniMac() }
                                OptionSelectButton(title: "Neo", value: "neo", currentSelection: $twinDeviceType) { TwinSkeletonNeo() }
                            }
                        }
                        .padding(.bottom, 4)
                        
                        
                        HStack(alignment: .top) {
                            Text("金属配色")
                                .padding(.top, 6)
                            Spacer()
                            
                            if twinDeviceType == "imac" {
                                VStack(alignment: .trailing, spacing: 8) {
                                    HStack(spacing: 8) {
                                        OptionSelectButton(title: "银色", value: "silver", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(white: 0.88), c2: Color(white: 0.55)) }
                                        OptionSelectButton(title: "蓝色", value: "blue", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.blue.opacity(0.8), c2: Color.blue.opacity(0.6)) }
                                        OptionSelectButton(title: "绿色", value: "green", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.green.opacity(0.8), c2: Color.green.opacity(0.6)) }
                                        OptionSelectButton(title: "粉红", value: "pink", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.pink.opacity(0.8), c2: Color.pink.opacity(0.6)) }
                                    }
                                    HStack(spacing: 8) {
                                        OptionSelectButton(title: "黄色", value: "yellow", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.yellow.opacity(0.8), c2: Color.yellow.opacity(0.6)) }
                                        OptionSelectButton(title: "橙色", value: "orange", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.orange.opacity(0.8), c2: Color.orange.opacity(0.6)) }
                                        OptionSelectButton(title: "紫色", value: "purple", currentSelection: $twinMacColor) { ColorSwatch(c1: Color.purple.opacity(0.8), c2: Color.purple.opacity(0.6)) }
                                    }
                                }
                            } else if twinDeviceType == "neo" {
                                HStack(spacing: 8) {
                                    OptionSelectButton(title: "银色", value: "silver", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(white: 0.88), c2: Color(white: 0.55)) }
                                    OptionSelectButton(title: "桃粉色", value: "peachPink", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(red: 0.95, green: 0.81, blue: 0.83), c2: Color(red: 0.86, green: 0.69, blue: 0.72)) }
                                    OptionSelectButton(title: "柑橘黄", value: "citrusYellow", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(red: 0.92, green: 0.80, blue: 0.40), c2: Color(red: 0.80, green: 0.70, blue: 0.30)) }
                                    OptionSelectButton(title: "靛蓝色", value: "indigoBlue", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(red: 0.35, green: 0.42, blue: 0.53), c2: Color(red: 0.25, green: 0.30, blue: 0.40)) }
                                }
                            } else if twinDeviceType == "mini" || twinDeviceType == "studio" {
                                HStack(spacing: 8) {
                                    OptionSelectButton(title: "银色", value: "silver", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(white: 0.88), c2: Color(white: 0.55)) }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    OptionSelectButton(title: "银色", value: "silver", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(white: 0.88), c2: Color(white: 0.55)) }
                                    OptionSelectButton(title: "深空灰", value: "spaceGray", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(white: 0.65), c2: Color(white: 0.40)) }
                                    OptionSelectButton(title: "午夜色", value: "midnight", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(red: 0.25, green: 0.26, blue: 0.31), c2: Color(red: 0.15, green: 0.16, blue: 0.21)) }
                                    OptionSelectButton(title: "星光色", value: "starlight", currentSelection: $twinMacColor) { ColorSwatch(c1: Color(red: 0.90, green: 0.88, blue: 0.82), c2: Color(red: 0.68, green: 0.65, blue: 0.59)) }
                                }
                            }
                        }
                        // State auto-correction logic bound to the containing view
                        .onChange(of: twinDeviceType) { _, _ in
                            if twinDeviceType == "imac" {
                                if !["silver", "blue", "green", "pink", "yellow", "orange", "purple"].contains(twinMacColor) {
                                    twinMacColor = "silver"
                                }
                            } else if twinDeviceType == "neo" {
                                if !["silver", "peachPink", "citrusYellow", "indigoBlue"].contains(twinMacColor) {
                                    twinMacColor = "silver"
                                }
                            } else if twinDeviceType == "mini" || twinDeviceType == "studio" {
                                twinMacColor = "silver"
                            } else {
                                if !["silver", "spaceGray", "midnight", "starlight"].contains(twinMacColor) {
                                    twinMacColor = "silver"
                                }
                            }
                        }
                    }
                    
                    Section("展示与动画") {
                        HStack(alignment: .top) {
                            Text("理线风格")
                                .padding(.top, 6)
                            Spacer()
                            HStack(spacing: 12) {
                                OptionSelectButton(title: "P人", value: "p", currentSelection: $twinCableStyle) { LiveWirePreview(style: "p") }
                                OptionSelectButton(title: "J人", value: "j", currentSelection: $twinCableStyle) { LiveWirePreview(style: "j") }
                            }
                        }
                        
                        Toggle("播放全局流动动画", isOn: $isTwinAnimated)
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
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            HStack(spacing: 4) {
                VStack(spacing: 3) {
                    pill(color: .yellow)
                    pill(color: .blue)
                }
                Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundColor(Color(white: 0.5))
                VStack(spacing: 3) {
                    pill(color: .white)
                    pill(color: .green)
                }
            }
        }
    }
    
    private func pill(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.25))
            .overlay(
                HStack(spacing: 2) {
                    Circle().fill(color).frame(width: 4, height: 4)
                    RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.5)).frame(width: 10, height: 2)
                }
            )
            .frame(width: 22, height: 10)
    }
}

struct CardsSkeleton: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            
            // Battery Card (Right)
            card(color: .green)
                .offset(x: 14)
                .zIndex(1)
            
            // System Card (Center)
            card(color: .white)
                .offset(x: 0)
                .zIndex(2)
            
            // Adapter Card (Left)
            card(color: .yellow)
                .offset(x: -14)
                .zIndex(3)
        }
    }
    
    private func card(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(white: 0.25))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.3), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            .overlay(
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.6)).frame(width: 8, height: 4)
                        Spacer()
                        Circle().fill(color).frame(width: 4, height: 4)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 0.5).fill(Color(white: 0.5)).frame(width: 12, height: 1.5)
                    RoundedRectangle(cornerRadius: 0.5).fill(Color(white: 0.5)).frame(width: 8, height: 1.5)
                }
                .padding(2)
            )
            .frame(width: 22, height: 28)
    }
}

// MARK: - Option Visualizations



struct LiveWirePreview: View {
    var style: String
    var body: some View {
        ZStack {
            // Lighter neutral background so the 0.15-opacity black cable stands out clearly
            LinearGradient(colors: [Color(white: 0.7), Color(white: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            EnergyWire3D(
                isActive: true, // Show the dark grey cable structure
                adapterPower: 65.0,
                isAnimated: true,
                isCharging: true,
                batteryLevel: 50, // 50 to show pulsing orange or neutral
                cableStyle: style
            )
            .frame(width: 140, height: 100) // Compact preview
            .offset(y: -10) // Move the wire up slightly so it is centered vertically
            .scaleEffect(0.3) // Fit in the button
        }
        .frame(width: 44, height: 32)
        .clipped()
    }
}

struct TwinSkeletonMBP: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 24, height: 16)
                RoundedRectangle(cornerRadius: 0.5).fill(Color(white: 0.7)).frame(width: 24, height: 2)
            }
        }
    }
}

struct TwinSkeletonMBA: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 24, height: 16)
                // Wedge shape logic via overlapping or simply thinner base
                RoundedRectangle(cornerRadius: 0.5).fill(Color(white: 0.7)).frame(width: 24, height: 1)
            }
        }
    }
}

struct TwinSkeletonMini: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 14, height: 5)
                Path { p in p.move(to: CGPoint(x: 1, y:0)); p.addLine(to: CGPoint(x: 13, y:0)); p.addLine(to: CGPoint(x: 12, y:1)); p.addLine(to: CGPoint(x: 2, y:1)) }
                    .fill(Color.black).frame(width: 14, height: 1)
            }
        }
    }
}

struct TwinSkeletonStudio: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5).fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 18, height: 8)
                Path { p in p.move(to: CGPoint(x: 1, y:0)); p.addLine(to: CGPoint(x: 17, y:0)); p.addLine(to: CGPoint(x: 15, y:1.5)); p.addLine(to: CGPoint(x: 3, y:1.5)) }
                    .fill(Color.black).frame(width: 18, height: 1.5)
            }
        }
    }
}

struct TwinSkeletonNeo: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 2).fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 20, height: 14)
                RoundedRectangle(cornerRadius: 1).fill(Color.orange).frame(width: 20, height: 2)
            }
        }
    }
}

struct TwinSkeletoniMac: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(white: 0.2), Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
            
            Path { path in
                path.move(to: CGPoint(x: 19, y: 0))
                path.addLine(to: CGPoint(x: 25, y: 0))
                path.addLine(to: CGPoint(x: 27, y: 20))
                path.addLine(to: CGPoint(x: 17, y: 20))
            }
            .fill(Color(white: 0.4))
            .offset(y: 8)
            
            VStack(spacing: 0) {
                Rectangle().fill(Color(white: 0.9))
                    .frame(width: 32, height: 18)
                    .clipShape(.rect(topLeadingRadius: 2, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 2))
                    .overlay(RoundedRectangle(cornerRadius: 1).fill(Color.black).frame(width: 30, height: 16))
                Rectangle().fill(Color(white: 0.7))
                    .frame(width: 32, height: 6)
            }
            .offset(y: -4)
        }
    }
}


struct SankeyStyleSkeletonStandard: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            Path { path in
                let w: CGFloat = 72
                let offset: CGFloat = 4
                
                let y1: CGFloat = 10
                let y2: CGFloat = 20
                let thick: CGFloat = 10
                
                path.move(to: CGPoint(x: offset, y: y1))
                path.addCurve(to: CGPoint(x: offset + w, y: y2), 
                              control1: CGPoint(x: offset + w * 0.5, y: y1), 
                              control2: CGPoint(x: offset + w * 0.5, y: y2))
                              
                path.addLine(to: CGPoint(x: offset + w, y: y2 + thick))
                
                path.addCurve(to: CGPoint(x: offset, y: y1 + thick), 
                              control1: CGPoint(x: offset + w * 0.5, y: y2 + thick), 
                              control2: CGPoint(x: offset + w * 0.5, y: y1 + thick))
                              
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.yellow.opacity(0.8), .yellow.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
        }
    }
}

struct SankeyStyleSkeletonWatchBand: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            Path { path in
                let w: CGFloat = 72
                let offset: CGFloat = 4
                
                let leftTopY: CGFloat = 6
                let leftBotY: CGFloat = 26
                
                let rightTopY: CGFloat = 14
                let rightBotY: CGFloat = 34
                
                let centerY: CGFloat = 20
                let halfThick: CGFloat = 3
                
                let curveW = w * 0.45
                
                // Top Edge
                path.move(to: CGPoint(x: offset, y: leftTopY))
                path.addCurve(to: CGPoint(x: offset + curveW, y: centerY - halfThick),
                              control1: CGPoint(x: offset + curveW * 0.6, y: leftTopY),
                              control2: CGPoint(x: offset + curveW * 0.4, y: centerY - halfThick))
                
                path.addLine(to: CGPoint(x: offset + w - curveW, y: centerY - halfThick))
                
                path.addCurve(to: CGPoint(x: offset + w, y: rightTopY),
                              control1: CGPoint(x: offset + w - curveW * 0.6, y: centerY - halfThick),
                              control2: CGPoint(x: offset + w - curveW * 0.4, y: rightTopY))
                              
                path.addLine(to: CGPoint(x: offset + w, y: rightBotY))
                
                // Bottom Edge
                path.addCurve(to: CGPoint(x: offset + w - curveW, y: centerY + halfThick),
                              control1: CGPoint(x: offset + w - curveW * 0.4, y: rightBotY),
                              control2: CGPoint(x: offset + w - curveW * 0.6, y: centerY + halfThick))
                              
                path.addLine(to: CGPoint(x: offset + curveW, y: centerY + halfThick))
                
                path.addCurve(to: CGPoint(x: offset, y: leftBotY),
                              control1: CGPoint(x: offset + curveW * 0.4, y: centerY + halfThick),
                              control2: CGPoint(x: offset + curveW * 0.6, y: leftBotY))
                              
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [.blue, .cyan.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
        }
    }
}

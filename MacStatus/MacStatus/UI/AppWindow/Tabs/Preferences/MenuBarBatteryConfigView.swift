import SwiftUI

struct MenuBarBatteryConfigView: View {
    @Environment(\.dismiss) private var dismiss

    // 主图标原子选项 (Atomic Options)
    @AppStorage("menuBarPowerStyle") private var menuBarPowerStyle: MenuBarPowerStyle = .graphic
    @AppStorage("batteryShellStyle") private var batteryShellStyle = "native"
    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryInnerContent") private var batteryInnerContent = "none"
    @AppStorage("batteryChargingIndicator") private var batteryChargingIndicator = "bolt"
    @AppStorage("batteryChargingBorderStyle") private var batteryChargingBorderStyle = "sharp"

    // 电池小人选项
    @AppStorage("batteryManLegLength") private var batteryManLegLength: BatteryManLegLength = .normal
    @AppStorage("batteryManShowFace") private var batteryManShowFace = false
    @AppStorage("batteryManShowArms") private var batteryManShowArms = false
    @AppStorage("batteryManShowPosture") private var batteryManShowPosture = false
    @AppStorage("batteryManShowAccessory") private var batteryManShowAccessory = false
    @AppStorage("batteryManFaceStyle") private var batteryManFaceStyle: BatteryManFaceStyle = .outline
    @AppStorage("batteryManHandItemStyle") private var batteryManHandItemStyle = "none"
    @AppStorage("batteryManHandItemSide") private var batteryManHandItemSide = "right"

    // 主图标选项
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    @AppStorage("mainIconGroupSpacing") private var mainIconGroupSpacing: Double = 4

    // 预览外观
    @AppStorage("previewIsDark") private var previewIsDark = true

    // 模拟器状态
    @State private var simCapacity: Int = 75
    @State private var simIsCharging: Bool = true
    @State private var simAdapterConnected: Bool = true
    @State private var isSimulatorExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Preview Section
                Section {
                    let mockVM = PreviewStatusViewModel(capacity: simCapacity, isCharging: simIsCharging, hasAdapter: simAdapterConnected)

                    if menuBarPowerStyle == .batteryMan {
                        MenuBarLabelRendererView(viewModel: mockVM, generatedMenuImage: nil)
                            .environment(\.colorScheme, previewIsDark ? .dark : .light)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(previewIsDark ? Color.black : Color.white)
                            .cornerRadius(12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        let batteryView = BatteryGraphicView(
                            capacity: simCapacity,
                            isCharging: simIsCharging,
                            isPowered: simAdapterConnected,
                            isColored: batteryFillStyle == "status_color",
                            chargingStyle: batteryChargingIndicator,
                            showNumber: batteryInnerContent == "inside",
                            isIOSStyle: batteryShellStyle == "ios",
                            borderStyle: batteryChargingBorderStyle
                        )

                        let batteryImage: NSImage? = {
                            if batteryShellStyle == "hidden" { return nil }
                            let renderer = ImageRenderer(content: batteryView.environment(\.colorScheme, previewIsDark ? .dark : .light).padding(1))
                            renderer.scale = 2.0
                            if let img = renderer.nsImage {
                                img.isTemplate = batteryFillStyle == "monochrome"
                                return img
                            }
                            return nil
                        }()

                        MenuBarLabelRendererView(viewModel: mockVM, generatedMenuImage: batteryImage)
                            .environment(\.colorScheme, previewIsDark ? .dark : .light)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(previewIsDark ? Color.black : Color.white)
                            .cornerRadius(12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    HStack {
                        Label("预览调节", systemImage: "slider.horizontal.3")
                        Spacer()
                        Button("设置电量参数...") {
                            isSimulatorExpanded.toggle()
                        }
                        .popover(isPresented: $isSimulatorExpanded, arrowEdge: .trailing) {
                            simulatorPanelView()
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Style Selection
                Section {
                    HStack(alignment: .top) {
                        Text("样式")
                            .padding(.top, 6)

                        Spacer()

                        HStack(spacing: 12) {
                            StyleSelectButton(title: "电池", value: .graphic, currentSelection: $menuBarPowerStyle) {
                                BatteryGraphicView(capacity: 80, isCharging: false, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: false)
                                    .scaleEffect(0.85)
                                    .padding(3)
                            }

                            StyleSelectButton(title: "电池小人", value: .batteryMan, currentSelection: $menuBarPowerStyle) {
                                BatteryManView(capacity: 75, isCharging: false, isColored: false, showBolt: false)
                                    .scaleEffect(0.9)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Battery Man Appearance Options
                if menuBarPowerStyle == .batteryMan {
                    Section {
                        Toggle("表情", isOn: $batteryManShowFace)
                        if batteryManShowFace {
                            HStack(alignment: .top) {
                                Text("样式")
                                    .padding(.top, 6)
                                Spacer()
                                HStack(spacing: 12) {
                                    FaceStyleSelectButton(title: "实心", value: .solid, currentSelection: $batteryManFaceStyle)
                                    FaceStyleSelectButton(title: "空心", value: .hollow, currentSelection: $batteryManFaceStyle)
                                    FaceStyleSelectButton(title: "Q版大头", value: .outline, currentSelection: $batteryManFaceStyle)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        Toggle("头饰", isOn: $batteryManShowAccessory)
                    } header: {
                        Text("头部")
                    } footer: {
                        Text("表情随电量变化，头饰反映充电或低电量状态")
                            .font(.caption)
                    }

                    Section {
                        Toggle("手臂", isOn: $batteryManShowArms)
                        if batteryManShowArms {
                            HStack(alignment: .top) {
                                Text("手持物品")
                                    .padding(.top, 6)
                                Spacer()
                                HStack(spacing: 12) {
                                    HandItemSelectButton(title: "无", value: "none", currentSelection: $batteryManHandItemStyle)
                                    HandItemSelectButton(title: "闪电", value: "bolt", currentSelection: $batteryManHandItemStyle)
                                    HandItemSelectButton(title: "适配器", value: "adapter", currentSelection: $batteryManHandItemStyle)
                                }
                            }
                            .padding(.vertical, 2)

                            HStack(alignment: .top) {
                                Text("持物手")
                                    .padding(.top, 6)
                                Spacer()
                                HStack(spacing: 12) {
                                    HandSideSelectButton(title: "左手", value: "left", currentSelection: $batteryManHandItemSide)
                                    HandSideSelectButton(title: "右手", value: "right", currentSelection: $batteryManHandItemSide)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("手臂")
                    } footer: {
                        Text("充电时手臂自动举起")
                            .font(.caption)
                    }

                    Section {
                        HStack(alignment: .top) {
                            Text("腿长")
                                .padding(.top, 6)

                            Spacer()

                            HStack(spacing: 12) {
                                LegLengthSelectButton(title: "短腿", value: .short, currentSelection: $batteryManLegLength)
                                LegLengthSelectButton(title: "长腿", value: .normal, currentSelection: $batteryManLegLength)
                            }
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("腿部")
                    }

                    Section {
                        Toggle("疲惫姿态", isOn: $batteryManShowPosture)
                    } header: {
                        Text("姿态")
                    } footer: {
                        Text("低电量时显示疲惫姿态")
                            .font(.caption)
                    }
                }

                // Battery Appearance Options
                if menuBarPowerStyle == .graphic {
                    // Section 1: Shell & Color
                    Section("外观") {
                        HStack(alignment: .top) {
                            Text("电池外形")
                                .padding(.top, 6)

                            Spacer()

                            HStack(spacing: 12) {
                                OptionSelectButton(title: "经典原生", value: "native", currentSelection: $batteryShellStyle) { ShellSkeletonNative() }
                                OptionSelectButton(title: "紧凑填充", value: "ios", currentSelection: $batteryShellStyle) { ShellSkeletonIOS() }
                                OptionSelectButton(title: "纯电量", value: "hidden", currentSelection: $batteryShellStyle) { ShellSkeletonHidden() }
                            }
                        }
                        .padding(.vertical, 2)

                        if batteryShellStyle != "hidden" {
                            HStack(alignment: .top) {
                                Text("色彩")
                                    .padding(.top, 6)

                                Spacer()

                                HStack(spacing: 12) {
                                    OptionSelectButton(title: "系统单色", value: "monochrome", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .primary.opacity(0.8), c2: .primary.opacity(0.5)) }
                                    OptionSelectButton(title: "电量彩色", value: "status_color", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .green, c2: .yellow) }
                                }
                            }
                            .padding(.vertical, 2)

                            // Low power warning: styled as a labeled row with color indicator
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(iconLowPowerColor ? .red : Color.primary.opacity(0.15))
                                        .frame(width: 8, height: 8)
                                    Text("低电量变红")
                                    Text("≤20%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $iconLowPowerColor)
                                    .labelsHidden()
                            }
                        }
                    }

                    // Section 2: Content Display
                    if batteryShellStyle != "hidden" {
                        Section("显示内容") {
                            HStack(alignment: .top) {
                                Text("电量信息")
                                    .padding(.top, 6)

                                Spacer()

                                HStack(spacing: 12) {
                                    OptionSelectButton(title: "无", value: "none", currentSelection: $batteryInnerContent) { InfoSkeletonNone() }
                                    OptionSelectButton(title: "外显", value: "outside", currentSelection: $batteryInnerContent) { InfoSkeletonOutside() }
                                    OptionSelectButton(title: "内嵌", value: "inside", currentSelection: $batteryInnerContent) { InfoSkeletonInside() }
                                }
                            }
                            .padding(.vertical, 2)

                            if batteryInnerContent != "inside" {
                                HStack(alignment: .top) {
                                    Text("充电状态")
                                        .padding(.top, 6)

                                    Spacer()

                                    HStack(spacing: 12) {
                                        OptionSelectButton(title: "闪电", value: "bolt", currentSelection: $batteryChargingIndicator) { ChargingSkeletonBolt() }
                                        OptionSelectButton(title: "经典闪电", value: "classic", currentSelection: $batteryChargingIndicator) { ChargingSkeletonClassic() }
                                        OptionSelectButton(title: "适配器", value: "plug", currentSelection: $batteryChargingIndicator) { ChargingSkeletonPlug() }
                                        OptionSelectButton(title: "无", value: "none", currentSelection: $batteryChargingIndicator) { ChargingSkeletonNone() }
                                    }
                                }
                                .padding(.vertical, 2)

                                if batteryChargingIndicator == "classic" || batteryChargingIndicator == "plug" {
                                    HStack {
                                        Text("描边风格")
                                            .padding(.top, 2)
                                        Spacer()
                                        Picker("", selection: $batteryChargingBorderStyle) {
                                            Text("标准").tag("sharp")
                                            Text("柔和").tag("soft")
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 120)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                    }
                }

                Section("间距") {
                    HStack {
                        Text("图标间距")
                        Spacer()
                        Slider(value: $mainIconGroupSpacing, in: 0...10, step: 1)
                            .frame(width: 100)
                        Text("\(Int(mainIconGroupSpacing))")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)
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
        .frame(minWidth: 360, minHeight: 320)
        .onAppear {
            // v1: split old batteryInnerContent "bolt" into separate charging indicator
            if !UserDefaults.standard.bool(forKey: "batteryChargingIndicatorMigrated") {
                if batteryInnerContent == "none" {
                    batteryChargingIndicator = "none"
                }
                if batteryInnerContent == "bolt" {
                    batteryInnerContent = "none"
                }
                UserDefaults.standard.set(true, forKey: "batteryChargingIndicatorMigrated")
            }
            // v2: rename "number" → "inside", migrate showPercentage → "outside"
            if !UserDefaults.standard.bool(forKey: "batteryInnerContentV2Migrated") {
                if batteryInnerContent == "number" {
                    batteryInnerContent = "inside"
                } else if batteryInnerContent == "none" {
                    let wasShowingPercentage = UserDefaults.standard.object(forKey: "showPercentage") as? Bool ?? true
                    if wasShowingPercentage {
                        batteryInnerContent = "outside"
                    }
                }
                UserDefaults.standard.set(true, forKey: "batteryInnerContentV2Migrated")
            }
        }
        .onChange(of: batteryInnerContent) { _, newValue in
            if newValue == "inside" {
                batteryChargingIndicator = "none"
            }
        }
    }

    @ViewBuilder
    private func simulatorPanelView() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("模拟电量")
                    .frame(width: 60, alignment: .leading)
                Slider(value: Binding(get: { Double(simCapacity) }, set: { simCapacity = Int($0) }), in: 0...100)
                Text("\(simCapacity)%")
                    .frame(width: 35, alignment: .trailing)
                    .monospacedDigit()
            }
            Toggle("接着适配器", isOn: $simAdapterConnected)
            Toggle("正在充电", isOn: $simIsCharging)
                .disabled(!simAdapterConnected)
        }
        .padding()
        .frame(width: 220)
        .onChange(of: simIsCharging) { _, newValue in
            if newValue { simAdapterConnected = true }
        }
        .onChange(of: simAdapterConnected) { _, newValue in
            if !newValue { simIsCharging = false }
        }
    }
}

// MARK: - Skeletons & Mock VM

class PreviewStatusViewModel: StatusViewModel {
    init(capacity: Int, isCharging: Bool, hasAdapter: Bool = true) {
        super.init()
        self.batteryData.currentCapacity = capacity
        self.batteryData.isCharging = isCharging
        self.powerFlow.isCharging = isCharging
        self.batteryData.voltage = 11400
        self.batteryData.amperage = isCharging ? 1500 : -1200
        self.batteryData.cycleCount = 120
        self.batteryData.temperature = 32.5
        self.batteryData.appleRawMaxCapacity = 100
        self.batteryData.appleMaxCapacity = 100
        self.batteryData.adapter = hasAdapter
            ? AdapterInfo(id: 1, familyCode: 1, name: "61W USB-C", designWatts: 61, realTimeWatts: hasAdapter ? 45 : 0, activeProfileIndex: 1, profiles: [], current: 2.25, voltage: 20.0, watts: hasAdapter ? 45 : 0)
            : nil
    }
}

struct ShellSkeletonNative: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 80, isCharging: false, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct ShellSkeletonIOS: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 80, isCharging: false, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: true)
                .scaleEffect(0.8)
        }
    }
}

struct ShellSkeletonHidden: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            Text("88%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

struct InfoSkeletonNone: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: false, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct InfoSkeletonOutside: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            HStack(spacing: 1) {
                BatteryGraphicView(capacity: 75, isCharging: false, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: false)
                    .scaleEffect(0.55)
                    .frame(width: 18, height: 10)
                Text("75%")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .fixedSize()
            }
        }
    }
}

struct InfoSkeletonInside: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: false, isColored: false, chargingStyle: "none", showNumber: true, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct ChargingSkeletonBolt: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: true, isColored: false, chargingStyle: "bolt", showNumber: false, isIOSStyle: false)
                .scaleEffect(0.85)
        }
    }
}

struct ChargingSkeletonClassic: View {
    @AppStorage("batteryChargingBorderStyle") private var batteryChargingBorderStyle = "sharp"

    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: true, isColored: false, chargingStyle: "classic", showNumber: false, isIOSStyle: false, borderStyle: batteryChargingBorderStyle)
                .scaleEffect(0.85)
        }
    }
}

// MARK: - Face Style Select Button

struct FaceStyleSelectButton: View {
    let title: String
    let value: BatteryManFaceStyle
    @Binding var currentSelection: BatteryManFaceStyle

    var isSelected: Bool { currentSelection == value }

    var body: some View {
        Button {
            currentSelection = value
        } label: {
            VStack(spacing: 4) {
                BatteryManView(capacity: 75, isCharging: false, isColored: false, showBolt: false, showFace: true, faceStyle: value)
                    .scaleEffect(0.9)
                    .frame(height: 20)

                Text(title)
                    .font(.caption2)
            }
            .frame(width: 56, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ChargingSkeletonPlug: View {
    @AppStorage("batteryChargingBorderStyle") private var batteryChargingBorderStyle = "sharp"

    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: true, isColored: false, chargingStyle: "plug", showNumber: false, isIOSStyle: false, borderStyle: batteryChargingBorderStyle)
                .scaleEffect(0.85)
        }
    }
}

// MARK: - Leg Length Select Button

struct LegLengthSelectButton: View {
    let title: String
    let value: BatteryManLegLength
    @Binding var currentSelection: BatteryManLegLength

    var isSelected: Bool { currentSelection == value }

    var body: some View {
        Button {
            currentSelection = value
        } label: {
            VStack(spacing: 4) {
                BatteryManView(capacity: 75, isCharging: false, isColored: false, showBolt: false, legLength: value)
                    .scaleEffect(0.85)
                    .frame(height: 24)

                Text(title)
                    .font(.caption2)
            }
            .frame(width: 56, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
struct ChargingSkeletonNone: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: true, isColored: false, chargingStyle: "none", showNumber: false, isIOSStyle: false)
                .scaleEffect(0.85)
        }
    }
}

// MARK: - Hand Item Select Button

struct HandItemSelectButton: View {
    let title: String
    let value: String
    @Binding var currentSelection: String

    var isSelected: Bool { currentSelection == value }

    var body: some View {
        Button {
            currentSelection = value
        } label: {
            Text(title)
                .font(.caption2)
                .frame(width: 40, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hand Side Select Button

struct HandSideSelectButton: View {
    let title: String
    let value: String
    @Binding var currentSelection: String

    var isSelected: Bool { currentSelection == value }

    var body: some View {
        Button {
            currentSelection = value
        } label: {
            Text(title)
                .font(.caption2)
                .frame(width: 40, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

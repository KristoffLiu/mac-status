import SwiftUI

struct MenuBarBatteryConfigView: View {
    @Environment(\.dismiss) private var dismiss

    // 主图标原子选项 (Atomic Options)
    @AppStorage("menuBarPowerStyle") private var menuBarPowerStyle: MenuBarPowerStyle = .graphic
    @AppStorage("batteryShellStyle") private var batteryShellStyle = "native"
    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryInnerContent") private var batteryInnerContent = "bolt"

    // 主图标选项
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    @AppStorage("mainIconGroupSpacing") private var mainIconGroupSpacing: Double = 4

    // 预览外观
    @AppStorage("previewIsDark") private var previewIsDark = true

    // 模拟器状态
    @State private var simCapacity: Int = 75
    @State private var simIsCharging: Bool = true
    @State private var isSimulatorExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Preview Section
                Section {
                    if menuBarPowerStyle == .batteryMan {
                        Text("🔋 电池人 (Coming Soon)")
                            .font(.headline)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(previewIsDark ? Color.black : Color.white)
                            .cornerRadius(12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        let mockVM = PreviewStatusViewModel(capacity: simCapacity, isCharging: simIsCharging)
                        let batteryView = BatteryGraphicView(
                            capacity: simCapacity,
                            isCharging: simIsCharging,
                            isColored: batteryFillStyle == "status_color",
                            showBolt: batteryInnerContent == "bolt" || batteryInnerContent == "number",
                            showNumber: batteryInnerContent == "number",
                            isIOSStyle: batteryShellStyle == "ios"
                        )

                        let batteryImage: NSImage? = {
                            if batteryShellStyle == "hidden" { return nil }
                            let renderer = ImageRenderer(content: batteryView.environment(\.colorScheme, previewIsDark ? .dark : .light))
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
                                Image(systemName: "battery.100")
                                    .font(.system(size: 20))
                                    .foregroundColor(.accentColor)
                            }

                            StyleSelectButton(title: "电池人", value: .batteryMan, currentSelection: $menuBarPowerStyle) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Battery Appearance Options
                if menuBarPowerStyle == .graphic {
                    Section {
                        HStack(alignment: .top) {
                            Text("外形")
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
                                Text("颜色")
                                    .padding(.top, 6)

                                Spacer()

                                HStack(spacing: 12) {
                                    OptionSelectButton(title: "系统单色", value: "monochrome", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .primary.opacity(0.8), c2: .primary.opacity(0.5)) }
                                    OptionSelectButton(title: "彩色生命条", value: "status_color", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .green, c2: .green.opacity(0.6)) }
                                }
                            }
                            .padding(.vertical, 2)

                            HStack(alignment: .top) {
                                Text("内部显示")
                                    .padding(.top, 6)

                                Spacer()

                                HStack(spacing: 12) {
                                    OptionSelectButton(title: "无内容", value: "none", currentSelection: $batteryInnerContent) { InnerSkeletonNone() }
                                    OptionSelectButton(title: "充电闪电", value: "bolt", currentSelection: $batteryInnerContent) { InnerSkeletonBolt() }
                                    OptionSelectButton(title: "电量数字", value: "number", currentSelection: $batteryInnerContent) { InnerSkeletonNumber() }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Section("其他") {
                        Toggle("低电量红色警告", isOn: $iconLowPowerColor)

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
            Toggle("正在充电", isOn: $simIsCharging)
        }
        .padding()
        .frame(width: 220)
    }
}

// MARK: - Skeletons & Mock VM

class PreviewStatusViewModel: StatusViewModel {
    init(capacity: Int, isCharging: Bool) {
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
        self.batteryData.adapter = AdapterInfo(id: 1, familyCode: 1, name: "61W USB-C", designWatts: 61, realTimeWatts: isCharging ? 45 : 0, activeProfileIndex: 1, profiles: [], current: 2.25, voltage: 20.0, watts: isCharging ? 45 : 0)
    }
}

struct ShellSkeletonNative: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 80, isCharging: false, isColored: false, showBolt: false, showNumber: false, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct ShellSkeletonIOS: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 80, isCharging: false, isColored: false, showBolt: false, showNumber: false, isIOSStyle: true)
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

struct InnerSkeletonNone: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: false, isColored: false, showBolt: false, showNumber: false, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct InnerSkeletonBolt: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: true, isColored: false, showBolt: true, showNumber: false, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

struct InnerSkeletonNumber: View {
    var body: some View {
        ZStack {
            Color.primary.opacity(0.05)
            BatteryGraphicView(capacity: 75, isCharging: false, isColored: false, showBolt: true, showNumber: true, isIOSStyle: false)
                .scaleEffect(0.8)
        }
    }
}

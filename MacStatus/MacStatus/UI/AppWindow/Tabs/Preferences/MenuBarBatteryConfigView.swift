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
            // Header with Close Button
            HStack {
                Text("电池图标")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(VisualEffectBackground(material: .headerView, blendingMode: .withinWindow))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("预览", systemImage: "menubar.rectangle")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Simulator Control
                            Button(action: { isSimulatorExpanded.toggle() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $isSimulatorExpanded, arrowEdge: .bottom) {
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
                            
                            // Appearance Toggle
                            Button(action: { previewIsDark.toggle() }) {
                                Image(systemName: previewIsDark ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(previewIsDark ? .yellow : .orange)
                            }
                            .buttonStyle(.plain)
                        }
                        
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
                            .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                    }
                    
                    // Options Sections
                    VStack(spacing: 20) {
                        // Style Grid
                        ConfigSection(title: "电能风格") {
                            HStack(spacing: 12) {
                                StyleSelectButton(title: "图形化电池", value: .graphic, currentSelection: $menuBarPowerStyle) {
                                     Image(systemName: "battery.100")
                                        .font(.system(size: 20))
                                        .foregroundColor(.accentColor)
                                }
                                
                                StyleSelectButton(title: "简约图标", value: .symbolic, currentSelection: $menuBarPowerStyle) {
                                    Image(systemName: "battery.50")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                }
                                
                                StyleSelectButton(title: "纯电量数字", value: .textOnly, currentSelection: $menuBarPowerStyle) {
                                    Text("88%")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                            }
                        }
                        
                        // Icon Grid
                        if menuBarPowerStyle == .graphic {
                            ConfigSection(title: "外壳形状") {
                                HStack(spacing: 12) {
                                    OptionSelectButton(title: "经典原生", value: "native", currentSelection: $batteryShellStyle) { ShellSkeletonNative() }
                                    OptionSelectButton(title: "紧凑填充", value: "ios", currentSelection: $batteryShellStyle) { ShellSkeletonIOS() }
                                    OptionSelectButton(title: "隐藏显示", value: "hidden", currentSelection: $batteryShellStyle) { ShellSkeletonHidden() }
                                }
                            }
                            
                            if batteryShellStyle != "hidden" {
                                ConfigSection(title: "色彩基调") {
                                    HStack(spacing: 12) {
                                        OptionSelectButton(title: "系统单色", value: "monochrome", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .primary.opacity(0.8), c2: .primary.opacity(0.5)) }
                                        OptionSelectButton(title: "彩色生命条", value: "status_color", currentSelection: $batteryFillStyle) { ColorSwatch(c1: .green, c2: .green.opacity(0.6)) }
                                    }
                                }
                                
                                ConfigSection(title: "内部显示物") {
                                    HStack(spacing: 12) {
                                        OptionSelectButton(title: "无内容", value: "none", currentSelection: $batteryInnerContent) { InnerSkeletonNone() }
                                        OptionSelectButton(title: "充电闪电", value: "bolt", currentSelection: $batteryInnerContent) { InnerSkeletonBolt() }
                                        OptionSelectButton(title: "电量数字", value: "number", currentSelection: $batteryInnerContent) { InnerSkeletonNumber() }
                                    }
                                }
                                
                                ConfigSection(title: "极低电量变色提醒") {
                                    Toggle("", isOn: $iconLowPowerColor)
                                        .labelsHidden()
                                }
                                
                                ConfigSection(title: "图标组内间距") {
                                    HStack(spacing: 8) {
                                        Slider(value: $mainIconGroupSpacing, in: 0...10, step: 1)
                                            .frame(width: 100)
                                        Text("\(Int(mainIconGroupSpacing))")
                                            .monospacedDigit()
                                            .foregroundColor(.secondary)
                                            .frame(width: 20, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 420, height: 600)
        .background(VisualEffectBackground(material: .windowBackground, blendingMode: .behindWindow))
    }
}

private struct ConfigSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Skeletons & Mock VM (Moved from SettingsView)

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
            Image(systemName: "eye.slash")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
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

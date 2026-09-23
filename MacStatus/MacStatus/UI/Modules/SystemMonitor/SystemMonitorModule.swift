import SwiftUI

struct SystemMonitorModule: View {
    @ObservedObject var service = SystemMonitorService.shared
    @AppStorage(AppPreferenceKeys.sysMonShowCPU) private var showCPU = true
    @AppStorage(AppPreferenceKeys.sysMonShowGPU) private var showGPU = true
    @AppStorage(AppPreferenceKeys.sysMonShowMemory) private var showMemory = true
    @AppStorage(AppPreferenceKeys.sysMonShowNetwork) private var showNetwork = true
    @AppStorage(AppPreferenceKeys.sysMonShowDisk) private var showDisk = true
    @AppStorage(AppPreferenceKeys.sysMonShowTemperature) private var showTemperature = true
    @AppStorage(AppPreferenceKeys.sysMonShowDetails) private var showDetails = true
    @AppStorage(AppPreferenceKeys.sysMonShowHeatmaps) private var showHeatmaps = true
    @AppStorage(AppPreferenceKeys.sysMonComputeHeight) private var computeHeight = 52.0
    @AppStorage(AppPreferenceKeys.sysMonSectionSpacing) private var sectionSpacing = 12.0
    @AppStorage(AppPreferenceKeys.sysMonHeatmapSize) private var heatmapSize = 8.0

    private var hasCompute: Bool { showCPU || showGPU }
    private var hasIO: Bool { showNetwork || showDisk }
    private var cellSize: Double { MonitorPixelGrid.bounded(heatmapSize, in: 4...20, fallback: 8) }

    var body: some View {
        VStack(alignment: .leading, spacing: MonitorPixelGrid.bounded(sectionSpacing, in: 4...24, fallback: 12)) {
            if hasCompute { compute }
            if hasCompute && (showMemory || hasIO) { PanelSeparator() }
            if showMemory {
                UnifiedMemCard(service: service, showDetails: showDetails)
            }
            if showMemory && hasIO { PanelSeparator() }
            if hasIO {
                HStack(alignment: .top, spacing: 12) {
                    if showNetwork {
                        MonitorIOCard(title: "网络", symbol: "network", firstLabel: "下载", secondLabel: "上传",
                                      firstValue: service.netDownKBps, secondValue: service.netUpKBps,
                                      firstHistory: service.netDownHistory, secondHistory: service.netUpHistory,
                                      firstColor: .cyan, secondColor: .green, isNetwork: true, showDetails: showDetails)
                    }
                    if showNetwork && showDisk { Divider().opacity(0.12) }
                    if showDisk {
                        MonitorIOCard(title: "磁盘", symbol: "internaldrive", firstLabel: "读取", secondLabel: "写入",
                                      firstValue: service.diskReadMBps, secondValue: service.diskWriteMBps,
                                      firstHistory: service.diskReadHistory, secondHistory: service.diskWriteHistory,
                                      firstColor: .yellow, secondColor: .orange, isNetwork: false, showDetails: showDetails)
                    }
                }
            }
            if !hasCompute && !showMemory && !hasIO {
                Label("未显示监控项目", systemImage: "chart.xyaxis.line")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
        }
        .padding(.vertical, 8)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var compute: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 6) {
            GridRow {
                if showCPU {
                    VStack(alignment: .leading, spacing: 6) {
                        metricHeader("CPU", value: service.cpuTotal, color: .blue)
                        if showDetails {
                            Text(String(format: "用户 %.0f%% · 系统 %.0f%%", service.cpuUser * 100, service.cpuSystem * 100))
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        if showHeatmaps {
                            CPUHeatmapView(loads: service.coreLoads, pCoreCount: service.pCoreCount,
                                           eCoreCount: service.eCoreCount, heatmapSize: cellSize)
                                .help("E：能效核心；P：性能核心。每个方块代表一个核心。")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if showGPU {
                    VStack(alignment: .leading, spacing: 6) {
                        metricHeader("GPU", value: service.gpuUtilization, color: .indigo)
                        if showDetails {
                            Text("总体负载").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        if showHeatmaps {
                            MonitorPixelView(data: [service.gpuUtilization], color: .indigo,
                                             height: cellSize * 2 + 2, occupancy: true)
                                .help("GPU 总体利用率；方块不代表独立 GPU 核心。")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            GridRow {
                if showCPU {
                    MonitorPixelView(data: service.cpuHistory, color: .blue, height: computeHeight)
                }
                if showGPU {
                    MonitorPixelView(data: service.gpuHistory, color: .indigo, height: computeHeight)
                }
            }
            if showTemperature && service.cpuTemperature > 1 {
                GridRow {
                    if showCPU {
                        Label(String(format: "%.0f°C", service.cpuTemperature), systemImage: "thermometer.medium")
                            .font(.system(size: 10, design: .rounded).monospacedDigit())
                            .foregroundStyle(service.cpuTemperature > 90 ? .red : .secondary)
                    }
                    if showGPU { Color.clear.frame(height: 0).gridCellUnsizedAxes([.horizontal, .vertical]) }
                }
            }
        }
    }

    private func metricHeader(_ title: String, value: Double, color: Color) -> some View {
        HStack {
            Text(title).font(.caption.weight(.semibold))
            Spacer(minLength: 4)
            Text(String(format: "%.1f%%", value * 100))
                .font(.system(.caption, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}

/// Both history charts and occupancy matrices use bounded, explicit dimensions.
private struct MonitorPixelView: View {
    let data: [Double]
    let color: Color
    let height: Double
    var scale: Double = 1
    var invertY = false
    var occupancy = false
    @AppStorage(AppPreferenceKeys.sysMonPixelShape) private var shape = 0
    @AppStorage(AppPreferenceKeys.sysMonPixelGap) private var gap = 1.5
    @AppStorage(AppPreferenceKeys.sysMonChartPixelSize) private var chartPixelSize = 5.0
    @AppStorage(AppPreferenceKeys.sysMonHeatmapSize) private var heatmapSize = 8.0
    @AppStorage(AppPreferenceKeys.sysMonBlockInterval) private var grouping = 0

    var body: some View {
        Canvas { context, bounds in
            let grid = MonitorPixelGrid(width: bounds.width, height: bounds.height,
                                        size: occupancy ? heatmapSize : chartPixelSize,
                                        gap: gap, grouping: grouping)
            let values = MonitorHistory.columns(data, count: grid.columns, scale: scale)
            let occupied = Int((MonitorHistory.ratio(data.last ?? 0) * Double(grid.columns * grid.rows)).rounded())
            for column in 0..<grid.columns {
                let filledRows = Int((values[column] * Double(grid.rows)).rounded(.up))
                for row in 0..<grid.rows {
                    let active = occupancy ? row * grid.columns + column < occupied
                        : (invertY ? row < filledRows : grid.rows - 1 - row < filledRows)
                    let rect = CGRect(x: bounds.width - grid.width + grid.x(column),
                                      y: (bounds.height - grid.height) / 2 + grid.y(row),
                                      width: grid.size, height: grid.size)
                    let path: Path = shape == 2 ? Path(ellipseIn: rect)
                        : shape == 1 ? Path(rect) : Path(roundedRect: rect, cornerRadius: grid.size * 0.18)
                    context.fill(path, with: .color(color.opacity(active ? 0.85 : 0.10)))
                }
            }
        }
        .frame(height: MonitorPixelGrid.bounded(height, in: 8...200, fallback: 52))
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityLabel(occupancy ? "当前占用" : "历史走势")
        .accessibilityValue(String(format: "%.1f%%", MonitorHistory.ratio((data.last ?? 0) / scale) * 100))
        .help(occupancy ? "当前占用比例" : "从左到右：较早 → 最新。显示最近 60 次采样，调整颗粒大小不会截短历史。")
    }
}

private struct UnifiedMemCard: View {
    @ObservedObject var service: SystemMonitorService
    let showDetails: Bool
    @AppStorage(AppPreferenceKeys.sysMonMemoryHeight) private var height = 64.0
    @AppStorage(AppPreferenceKeys.sysMonMemoryLayout) private var layout = 0
    private var ratio: Double { service.memTotalGB > 0 ? MonitorHistory.ratio(service.memUsedGB / service.memTotalGB) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("统一内存").font(.caption.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f / %.0f GB", service.memUsedGB, service.memTotalGB))
                    .font(.system(.caption, design: .rounded).monospacedDigit()).foregroundStyle(.purple)
            }
            HStack(spacing: 12) {
                if layout != 2 {
                    MonitorPixelView(data: service.memHistory, color: .purple, height: height)
                }
                if layout == 0 { Divider().opacity(0.12) }
                if layout != 1 {
                    MonitorPixelView(data: [ratio], color: .purple, height: height, occupancy: true)
                }
            }
            .frame(height: MonitorPixelGrid.bounded(height, in: 24...200, fallback: 64))
            if showDetails {
                HStack {
                    Text(String(format: "已用 %.0f%%", ratio * 100))
                    Spacer()
                    Text(String(format: "GPU 参考 %.1f GB", service.gpuMemUsedGB))
                }
                .font(.system(size: 10, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .help("已用量按活跃页、不可分页内存和压缩页估算，不代表 macOS 内存压力。GPU 统计口径可能与系统已用量重叠，因此单独列出，不累加。")
            }
        }
    }
}

private struct MonitorIOCard: View {
    let title: LocalizedStringKey
    let symbol: String
    let firstLabel: LocalizedStringKey
    let secondLabel: LocalizedStringKey
    let firstValue: Double
    let secondValue: Double
    let firstHistory: [Double]
    let secondHistory: [Double]
    let firstColor: Color
    let secondColor: Color
    let isNetwork: Bool
    let showDetails: Bool
    @AppStorage(AppPreferenceKeys.sysMonIOHeight) private var height = 52.0
    @AppStorage(AppPreferenceKeys.sysMonSymmetricGraph) private var symmetric = false
    private var scale: Double { MonitorHistory.scale(firstHistory, secondHistory, minimum: isNetwork ? 1 : 0.1) }
    private var chartHeight: Double { (MonitorPixelGrid.bounded(height, in: 32...120, fallback: 52) - 4) / 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol).font(.caption.weight(.semibold))
            VStack(spacing: 4) {
                MonitorPixelView(data: firstHistory, color: firstColor, height: chartHeight, scale: scale)
                MonitorPixelView(data: secondHistory, color: secondColor, height: chartHeight, scale: scale, invertY: symmetric)
            }
            valueRow(firstLabel, value: firstValue, color: firstColor)
            valueRow(secondLabel, value: secondValue, color: secondColor)
            if showDetails {
                Text("满刻度 \(formatted(scale))")
                    .font(.system(size: 9, design: .rounded).monospacedDigit()).foregroundStyle(.secondary)
                    .help("两条曲线共用最近 60 次采样的峰值刻度。")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func valueRow(_ label: LocalizedStringKey, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
            Spacer(minLength: 2)
            Text(formatted(value)).monospacedDigit()
        }
        .font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
    }

    private func formatted(_ value: Double) -> String {
        if isNetwork {
            return value >= 1024 ? String(format: "%.1f MB/s", value / 1024) : String(format: "%.0f KB/s", value)
        }
        return value >= 1 ? String(format: "%.1f MB/s", value) : String(format: "%.0f KB/s", value * 1024)
    }
}
// MARK: - CPU Heatmap（正方形格子）
struct CPUHeatmapView: View {
    let loads: [Double]
    let pCoreCount: Int
    let eCoreCount: Int
    let heatmapSize: CGFloat

    private var eCoreLoads: [Double] {
        if eCoreCount > 0 && eCoreCount + pCoreCount <= loads.count {
            return Array(loads.prefix(eCoreCount))
        }
        return []
    }
    
    private var pCoreLoads: [Double] {
        if eCoreCount > 0 && eCoreCount + pCoreCount <= loads.count {
            return Array(loads.dropFirst(eCoreCount).prefix(pCoreCount))
        }
        return loads
    }

    private var eColumns: [GridItem] {
        return [GridItem(.adaptive(minimum: heatmapSize, maximum: heatmapSize), spacing: 2)]
    }

    private var pColumns: [GridItem] {
        return [GridItem(.adaptive(minimum: heatmapSize * 1.5, maximum: heatmapSize * 1.5), spacing: 2)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !eCoreLoads.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("E")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.blue.opacity(0.7))
                        .frame(width: 8, alignment: .leading)
                        .padding(.top, 1)

                    LazyVGrid(columns: eColumns, alignment: .leading, spacing: 2) {
                        ForEach(0..<eCoreLoads.count, id: \.self) { i in
                            HeatCell(load: eCoreLoads[i])
                                .frame(width: heatmapSize, height: heatmapSize)
                        }
                    }
                    .drawingGroup()
                }
            }

            HStack(alignment: .top, spacing: 6) {
                if !eCoreLoads.isEmpty {
                    Text("P")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.orange.opacity(0.7))
                        .frame(width: 8, alignment: .leading)
                        .padding(.top, 1)
                }

                    LazyVGrid(columns: pColumns, alignment: .leading, spacing: 2) {
                        ForEach(0..<pCoreLoads.count, id: \.self) { i in
                            HeatCell(load: pCoreLoads[i])
                                .frame(width: heatmapSize * 1.5, height: heatmapSize * 1.5)
                        }
                    }
                    .drawingGroup()
            }
        }
    }
}

struct HeatCell: View {
    let load: Double

    @AppStorage(AppPreferenceKeys.sysMonPixelShape) private var pixelShape: Int = 0

    var body: some View {
        Group {
            if pixelShape == 2 {
                Circle()
                    .fill(cellColor)
                    .overlay(Circle().stroke(cellColor.opacity(0.3), lineWidth: 0.5))
            } else if pixelShape == 1 {
                Rectangle()
                    .fill(cellColor)
                    .overlay(Rectangle().stroke(cellColor.opacity(0.3), lineWidth: 0.5))
            } else {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(cellColor)
                    .overlay(RoundedRectangle(cornerRadius: 1.5, style: .continuous).stroke(cellColor.opacity(0.3), lineWidth: 0.5))
            }
        }
        .shadow(color: load > 0.75 ? cellColor.opacity(0.55) : .clear, radius: 1.5)
    }

    private var cellColor: Color {
        switch load {
        case ..<0.08: return Color.primary.opacity(0.09)
        case 0.08..<0.3:  return Color(hue: 0.35, saturation: 0.8, brightness: 0.7).opacity(0.5 + load * 0.9)
        case 0.3..<0.65:  return Color(hue: 0.12, saturation: 0.9, brightness: 0.9).opacity(0.78)
        case 0.65..<0.85: return Color(hue: 0.05, saturation: 1.0, brightness: 1.0).opacity(0.88)
        default:          return Color.red.opacity(0.92)
        }
    }
}


struct SystemMonitorConfigView: View {
    @AppStorage(AppPreferenceKeys.sysMonShowCPU) private var showCPU = true
    @AppStorage(AppPreferenceKeys.sysMonShowGPU) private var showGPU = true
    @AppStorage(AppPreferenceKeys.sysMonShowMemory) private var showMemory = true
    @AppStorage(AppPreferenceKeys.sysMonShowNetwork) private var showNetwork = true
    @AppStorage(AppPreferenceKeys.sysMonShowDisk) private var showDisk = true
    @AppStorage(AppPreferenceKeys.sysMonShowTemperature) private var showTemperature = true
    @AppStorage(AppPreferenceKeys.sysMonShowDetails) private var showDetails = true
    @AppStorage(AppPreferenceKeys.sysMonShowHeatmaps) private var showHeatmaps = true
    @AppStorage(AppPreferenceKeys.sysMonComputeHeight) private var computeHeight = 52.0
    @AppStorage(AppPreferenceKeys.sysMonMemoryHeight) private var memoryHeight = 64.0
    @AppStorage(AppPreferenceKeys.sysMonIOHeight) private var ioHeight = 52.0
    @AppStorage(AppPreferenceKeys.sysMonMemoryLayout) private var memoryLayout = 0
    @AppStorage(AppPreferenceKeys.sysMonSectionSpacing) private var sectionSpacing = 12.0
    @AppStorage(AppPreferenceKeys.sysMonSymmetricGraph) private var symmetricGraph = false
    @AppStorage(AppPreferenceKeys.sysMonPixelGap) private var pixelGap = 1.5
    @AppStorage(AppPreferenceKeys.sysMonPixelShape) private var pixelShape = 0
    @AppStorage(AppPreferenceKeys.sysMonBlockInterval) private var blockInterval = 0
    @AppStorage(AppPreferenceKeys.sysMonChartPixelSize) private var chartPixelSize = 5.0
    @AppStorage(AppPreferenceKeys.sysMonHeatmapSize) private var heatmapSize = 8.0
    @AppStorage(AppPreferenceKeys.panelTheme) private var panelTheme = "system"
    @Environment(\.dismiss) private var dismiss

    private var preferredScheme: ColorScheme? {
        switch panelTheme {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("面板预览").font(.headline)
                Text("与悬浮面板同宽 · 修改即时保存")
                    .font(.caption).foregroundStyle(.secondary)
                ScrollView {
                    SystemMonitorModule()
                        .padding(.horizontal, PanelLayout.contentInset)
                        .frame(width: PanelLayout.width)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .scrollIndicators(.never)
                .scrollBounceBehavior(.basedOnSize)
                Text("面板关闭时暂停采样，预览保留最近数据。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(width: PanelLayout.width + 32)
            Rectangle().fill(.primary.opacity(0.05)).frame(width: 0.5)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        MonitorSettingsSection("显示项目") {
                            MonitorSettingsToggle("CPU", isOn: $showCPU)
                            MonitorSettingsToggle("GPU", isOn: $showGPU)
                            MonitorSettingsToggle("统一内存", isOn: $showMemory)
                            MonitorSettingsToggle("网络", isOn: $showNetwork)
                            MonitorSettingsToggle("磁盘", isOn: $showDisk)
                        }
                        MonitorSettingsSection("统一内存布局") {
                            MonitorSettingsPicker("内容", selection: $memoryLayout) {
                                Text("走势与占用矩阵").tag(0)
                                Text("仅走势").tag(1)
                                Text("仅占用矩阵").tag(2)
                            }
                            .pickerStyle(.menu)
                            MonitorSizeControl(title: "内存图表高度", value: $memoryHeight, range: 24...200, step: 2)
                            Text("只调整图表区域，标题与说明会自动留出空间。")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .disabled(!showMemory)
                        MonitorSettingsSection("布局与尺寸") {
                            MonitorSizeControl(title: "CPU / GPU 走势高度", value: $computeHeight, range: 24...160, step: 2)
                                .disabled(!showCPU && !showGPU)
                            MonitorSizeControl(title: "网络 / 磁盘走势高度", value: $ioHeight, range: 32...120, step: 2)
                                .disabled(!showNetwork && !showDisk)
                            MonitorSizeControl(title: "区域间距", value: $sectionSpacing, range: 4...24, step: 1)
                            MonitorSettingsPicker("双曲线方向", selection: $symmetricGraph) {
                                Text("同向向上").tag(false)
                                Text("上下镜像").tag(true)
                            }
                            .disabled(!showNetwork && !showDisk)
                        }
                        MonitorSettingsSection("辅助信息") {
                            MonitorSettingsToggle("CPU / GPU 负载方块", isOn: $showHeatmaps)
                                .disabled(!showCPU && !showGPU)
                            MonitorSettingsToggle("CPU 温度（可读取时）", isOn: $showTemperature).disabled(!showCPU)
                            MonitorSettingsToggle("显示明细与刻度说明", isOn: $showDetails)
                        }
                        MonitorSettingsSection("像素样式") {
                            MonitorSettingsPicker("形状", selection: $pixelShape) {
                                Text("圆角方块").tag(0)
                                Text("方块").tag(1)
                                Text("圆点").tag(2)
                            }
                            MonitorSizeControl(title: "走势颗粒大小", value: $chartPixelSize, range: 2...10, step: 0.5)
                            MonitorSizeControl(title: "负载方块大小", value: $heatmapSize, range: 4...20, step: 1)
                            MonitorSizeControl(title: "图表颗粒间距", value: $pixelGap, range: 0...4, step: 0.5)
                            MonitorSettingsPicker("每四格增加分隔", selection: $blockInterval) {
                                Text("无").tag(0)
                                Text("行").tag(1)
                                Text("列").tag(2)
                                Text("行和列").tag(3)
                            }
                            Text("颗粒大小影响精细度，不改变区域高度。CPU 核心方块会按数量自动换行。")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                }
                .scrollIndicators(.never)
                .scrollBounceBehavior(.basedOnSize)
                .toggleStyle(.switch)
                .controlSize(.small)
                .pickerStyle(.menu)
                PanelSeparator().padding(.horizontal, 16)
                HStack {
                    Button("恢复本模块默认") { AppPreferences.resetSystemMonitor() }
                    Spacer()
                    Button("完成") { dismiss() }.keyboardShortcut(.defaultAction)
                }
                .padding(12)
            }
            .frame(width: 352)
        }
        .frame(height: 480)
        .background(VisualEffectBackground(material: .popover, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .preferredColorScheme(preferredScheme)
    }
}

private struct MonitorSizeControl: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value, specifier: "%.1f") pt")
                    .monospacedDigit().foregroundStyle(.secondary)
                Stepper(title, value: $value, in: range, step: step).labelsHidden()
            }
            Slider(value: Binding(
                get: { value },
                set: { value = min(range.upperBound, max(range.lowerBound, ($0 / step).rounded() * step)) }
            ), in: range) { Text(title) }
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}


private struct MonitorSettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}


private struct MonitorSettingsToggle: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn).labelsHidden()
        }
    }
}

private struct MonitorSettingsPicker<Selection: Hashable, Content: View>: View {
    let title: LocalizedStringKey
    @Binding var selection: Selection
    let content: Content

    init(_ title: LocalizedStringKey, selection: Binding<Selection>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            Picker(title, selection: $selection) { content }.labelsHidden()
        }
    }
}

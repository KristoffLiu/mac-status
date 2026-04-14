import SwiftUI

// MARK: - Main Module
struct SystemMonitorModule: View {
    @ObservedObject var service = SystemMonitorService.shared
    
    @AppStorage("sysMonShowCompute") private var showCompute = true
    @AppStorage("sysMonShowMemory") private var showMemory = true
    @AppStorage("sysMonShowNetDisk") private var showNetDisk = true
    @AppStorage("sysMonSymmetricGraph") private var symmetricGraph = false
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5
    @AppStorage("sysMonChartPixelSize") private var chartPixelSize: Double = 5.0
    @AppStorage("sysMonPixelDensity") private var pixelDensity: Double = 1.0
    @AppStorage("sysMonHeatmapSize") private var heatmapSize: Double = 8.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── 3x2 Grid Layout ──────────────────────────────────────────────
            VStack(spacing: 12) {
                if showCompute {
                    // Row 1: Compute (CPU & GPU)
                    HStack(alignment: .top, spacing: 8) {
                        // CPU Card
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Text("CPU")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.primary.opacity(0.7))
                            
                            if service.cpuTemperature > 1 {
                                Spacer().frame(width: 4)
                                TempBadgeView(temp: service.cpuTemperature)
                            }
                            
                            Spacer()
                            Text(String(format: "%.1f%%", service.cpuTotal * 100))
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundColor(cpuTotalColor(service.cpuTotal))
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 6) {
                            HStack(spacing: 2) {
                                Circle().fill(Color.blue.opacity(0.8)).frame(width: 5, height: 5)
                                Text(String(format: "%.0f%%", service.cpuUser * 100))
                                    .font(.system(size: 9, design: .rounded).monospacedDigit())
                                    .foregroundColor(.secondary)
                                Text("usr")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            HStack(spacing: 2) {
                                Circle().fill(Color.orange.opacity(0.8)).frame(width: 5, height: 5)
                                Text(String(format: "%.0f%%", service.cpuSystem * 100))
                                    .font(.system(size: 9, design: .rounded).monospacedDigit())
                                    .foregroundColor(.secondary)
                                Text("sys")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }

                        // 正方形热力图
                        CPUHeatmapView(loads: service.coreLoads, pCoreCount: service.pCoreCount, eCoreCount: service.eCoreCount, heatmapSize: CGFloat(heatmapSize))
                        
                        Spacer(minLength: 0)
                        
                        // CPU历史走势方格矩阵
                        PixelBarChartView(
                            data: service.cpuHistory,
                            maxRows: 8,
                            baseColor: cpuTotalColor(service.cpuTotal),
                            gap: CGFloat(pixelGap),
                            chartPixelSize: chartPixelSize
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Divider().opacity(0.3)

                    // GPU Card
                    GPUMatrixCard(
                        utilization: service.gpuUtilization,
                        history: service.gpuHistory,
                        heatmapSize: CGFloat(heatmapSize),
                        chartPixelSize: chartPixelSize
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                } // end showCompute

                if showCompute && (showMemory || showNetDisk) {
                    Divider().opacity(0.4).padding(.horizontal, 8)
                }

                if showMemory {
                // Row 2: Unified Memory
                UnifiedMemCard(
                    sysUsedGB: service.memUsedGB,
                    gpuUsedGB: service.gpuMemUsedGB,
                    totalGB: service.memTotalGB,
                    sysHistory: service.memHistory,
                    gpuHistory: service.gpuMemHistory,
                    pressure: service.memPressure,
                    heatmapSize: CGFloat(heatmapSize),
                    chartPixelSize: chartPixelSize
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } // end showMemory

                if showMemory && showNetDisk {
                    Divider().opacity(0.4).padding(.horizontal, 8)
                }

                if showNetDisk {
                // Row 3: Network & Disk
                HStack(alignment: .top, spacing: 8) {
                    NetMatrixCard(
                        downKBps:    service.netDownKBps,
                        upKBps:      service.netUpKBps,
                        downHistory: service.netDownHistory,
                        upHistory:   service.netUpHistory,
                        symmetricGraph: symmetricGraph,
                        chartPixelSize: chartPixelSize
                    )
                    .frame(maxWidth: .infinity, alignment: .top)

                    Divider().opacity(0.3)

                    DiskMatrixCard(
                        readMBps:     service.diskReadMBps,
                        writeMBps:    service.diskWriteMBps,
                        readHistory:  service.diskReadHistory,
                        writeHistory: service.diskWriteHistory,
                        symmetricGraph: symmetricGraph,
                        chartPixelSize: chartPixelSize
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                } // end showNetDisk
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func cpuTotalColor(_ v: Double) -> Color {
        if v > 0.8 { return .red }
        if v > 0.5 { return .orange }
        return .green
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
        .animation(.easeInOut(duration: 0.3), value: loads)
    }
}

struct HeatCell: View {
    let load: Double

    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0

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

// MARK: - 通用像素条形图视图（X:时间, Y:数值）
struct PixelBarChartView: View {
    let data: [Double]         // 时序数据，左侧最旧，右侧最新
    let maxRows: Int
    let baseColor: Color
    let gap: CGFloat
    var invertY: Bool = false
    let chartPixelSize: Double

    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0
    @AppStorage("sysMonPixelDensity") private var pixelDensity: Double = 1.0
    @AppStorage("sysMonBlockInterval") private var blockInterval: Int = 0

    var body: some View {
        let finalRows = max(1, Int(ceil(Double(maxRows) * pixelDensity)))
        
        let rowGroups = (blockInterval == 1 || blockInterval == 3) ? max(0, finalRows - 1) / 4 : 0
        let extraHTotal = CGFloat(rowGroups) * gap
        let totalGapsH = gap * CGFloat(max(finalRows - 1, 0)) + extraHTotal
        
        let size = CGFloat(chartPixelSize)
        let calculatedHeight = max(1, size * CGFloat(finalRows) + totalGapsH)

        return GeometryReader { geo in
            let avgCellW = size + gap + ((blockInterval >= 2) ? gap / 4 : 0)
            let maxCols = Int(ceil((geo.size.width + gap) / avgCellW))
            let cols = maxCols > 0 ? maxCols : 1
            
            let visibleData = data.count > cols ? Array(data.suffix(cols)) : data
            let c = visibleData.count > 0 ? visibleData.count : 1
            
            let colGroups = (blockInterval >= 2) ? max(0, c - 1) / 4 : 0
            let extraWTotal = CGFloat(colGroups) * gap
            
            let totalW = size * CGFloat(c) + gap * CGFloat(max(c - 1, 0)) + extraWTotal
            let totalH = size * CGFloat(finalRows) + totalGapsH
            let offsetX = geo.size.width - totalW
            let offsetY = (geo.size.height - totalH) / 2

            let maxVal = 1.0

            Canvas { ctx, _ in
                for col in 0..<c {
                    let v = visibleData[col]
                    let ratio = v / maxVal
                    let fillRows = Int(ceil(ratio * Double(finalRows)))
                    
                    for row in 0..<finalRows {
                        let isFilled: Bool
                        if invertY {
                            isFilled = row < fillRows
                        } else {
                            isFilled = (finalRows - 1 - row) < fillRows
                        }
                        
                        let addColGap = (blockInterval >= 2) ? CGFloat(col / 4) * gap : 0
                        let addRowGap = (blockInterval == 1 || blockInterval == 3) ? CGFloat(row / 4) * gap : 0
                        
                        let x = offsetX + (size + gap) * CGFloat(col) + addColGap
                        let y = offsetY + (size + gap) * CGFloat(row) + addRowGap
                        let rect = CGRect(x: x, y: y, width: size, height: size)
                        
                        let path: Path
                        if pixelShape == 2 {
                            path = Path(ellipseIn: rect)
                        } else if pixelShape == 1 {
                            path = Path(rect)
                        } else {
                            path = Path(roundedRect: rect, cornerRadius: max(1.0, size * 0.15)) 
                        }

                        if isFilled {
                            ctx.fill(path, with: .color(baseColor.opacity(0.85)))
                        } else {
                            ctx.fill(path, with: .color(baseColor.opacity(0.1)))
                        }
                    }
                }
            }
        }
        .frame(height: calculatedHeight)
    }
}

// MARK: - Unified Memory Matrix Card
struct UnifiedMemCard: View {
    let sysUsedGB: Double
    let gpuUsedGB: Double
    let totalGB: Double
    let sysHistory: [Double]
    let gpuHistory: [Double]
    let pressure: Double
    let heatmapSize: CGFloat
    let chartPixelSize: Double
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5
    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0

    private var sysRatio: Double { totalGB > 0 ? sysUsedGB / totalGB : 0 }
    private var gpuRatio: Double { totalGB > 0 ? gpuUsedGB / totalGB : 0 }
    
    private var pressureColor: Color {
        if pressure > 0.85 { return .red }
        if pressure > 0.65 { return .orange }
        return .purple.opacity(0.8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Text("统一内存")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary.opacity(0.7))
                
                Spacer()
                
                // Detailed Breakdown inline
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Circle().fill(pressureColor).frame(width: 5, height: 5)
                        Text(String(format: "%.1fGB", sysUsedGB))
                            .font(.system(size: 9, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("系统")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    HStack(spacing: 2) {
                        Circle().fill(Color.teal.opacity(0.8)).frame(width: 5, height: 5)
                        Text(String(format: "%.1fGB", gpuUsedGB))
                            .font(.system(size: 9, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("图形")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                Spacer().frame(width: 4)
                
                Text(String(format: "%.0fGB", totalGB))
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundColor(pressureColor)
                    .fontWeight(.semibold)
            }

            HStack(alignment: .top, spacing: 8) {
                // 左侧: 堆叠时序走势图
                StackedPixelBarChartView(
                    bottomData: sysHistory,
                    topData: gpuHistory,
                    maxRows: 8,
                    bottomColor: pressureColor,
                    topColor: .teal,
                    gap: CGFloat(pixelGap),
                    chartPixelSize: chartPixelSize
                )
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Divider().opacity(0.3)
                
                // 右侧: 热力图阵列 (增加到 6 行)
                GeometryReader { geo in
                    let spacing: CGFloat = 2
                    let cols = Int((geo.size.width + spacing) / (heatmapSize + spacing))
                    let actualCols = max(cols, 1)
                    
                    let rows = Int((geo.size.height + spacing) / (heatmapSize + spacing))
                    let actualRows = max(rows, 1)
                    let c = actualCols * actualRows 
                    
                    let gridCols = Array(repeating: GridItem(.fixed(heatmapSize), spacing: spacing), count: actualCols)
                    
                    LazyVGrid(columns: gridCols, alignment: .leading, spacing: spacing) {
                        ForEach(0..<c, id: \.self) { i in
                            let threshold = Double(i) / Double(c)
                            let isSys = threshold < sysRatio
                            let isGpu = threshold >= sysRatio && threshold < (sysRatio + gpuRatio)
                            let fillCol = isSys ? pressureColor.opacity(0.8) : (isGpu ? Color.teal.opacity(0.8) : Color.primary.opacity(0.09))
                            let strokeCol = isSys ? pressureColor.opacity(0.3) : (isGpu ? Color.teal.opacity(0.3) : Color.clear)
                            
                            Group {
                                if pixelShape == 2 {
                                    Circle()
                                        .fill(fillCol)
                                        .overlay(Circle().stroke(strokeCol, lineWidth: 0.5))
                                } else if pixelShape == 1 {
                                    Rectangle()
                                        .fill(fillCol)
                                        .overlay(Rectangle().stroke(strokeCol, lineWidth: 0.5))
                                } else {
                                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                        .fill(fillCol)
                                        .overlay(RoundedRectangle(cornerRadius: 1.5, style: .continuous).stroke(strokeCol, lineWidth: 0.5))
                                }
                            }
                            .frame(width: heatmapSize, height: heatmapSize)
                        }
                    }
                    .drawingGroup()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Stacked Pixel Bar Chart View
struct StackedPixelBarChartView: View {
    let bottomData: [Double]
    let topData: [Double]
    let maxRows: Int
    let bottomColor: Color
    let topColor: Color
    let gap: CGFloat
    let chartPixelSize: Double
    
    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0
    @AppStorage("sysMonPixelDensity") private var pixelDensity: Double = 1.0
    @AppStorage("sysMonBlockInterval") private var blockInterval: Int = 0
    
    var body: some View {
        let finalRows = max(1, Int(ceil(Double(maxRows) * pixelDensity)))
        
        let rowGroups = (blockInterval == 1 || blockInterval == 3) ? max(0, finalRows - 1) / 4 : 0
        let extraHTotal = CGFloat(rowGroups) * gap
        let totalGapsH = gap * CGFloat(max(finalRows - 1, 0)) + extraHTotal
        
        let size = CGFloat(chartPixelSize)
        let calculatedHeight = max(1, size * CGFloat(finalRows) + totalGapsH)
        
        return GeometryReader { geo in
            let avgCellW = size + gap + ((blockInterval >= 2) ? gap / 4 : 0)
            let c = Int((geo.size.width + gap) / avgCellW)
            let actualCols = max(1, c)
            
            let bData = bottomData.suffix(actualCols)
            let tData = topData.suffix(actualCols)
            let bVisible = Array(repeating: 0.0, count: max(0, actualCols - bData.count)) + bData
            let tVisible = Array(repeating: 0.0, count: max(0, actualCols - tData.count)) + tData
            
            let colGroups = (blockInterval >= 2) ? max(0, actualCols - 1) / 4 : 0
            let extraWTotal = CGFloat(colGroups) * gap
            
            let totalW = size * CGFloat(actualCols) + gap * CGFloat(max(actualCols - 1, 0)) + extraWTotal
            let totalH = size * CGFloat(finalRows) + totalGapsH
            let offsetX = geo.size.width - totalW
            let offsetY = (geo.size.height - totalH) / 2
            
            let maxVal = 1.0 
            
            Canvas { ctx, _ in
                for col in 0..<actualCols {
                    let bRatio = bVisible[col] / maxVal
                    let tRatio = tVisible[col] / maxVal
                    
                    let bFillRows = Int(ceil(bRatio * Double(finalRows)))
                    let tFillRows = Int(ceil(tRatio * Double(finalRows)))
                    
                    for row in 0..<finalRows {
                        let isBottomFilled = (finalRows - 1 - row) < bFillRows
                        let isTopFilled = (finalRows - 1 - row) >= bFillRows && (finalRows - 1 - row) < (bFillRows + tFillRows)
                        
                        let addColGap = (blockInterval >= 2) ? CGFloat(col / 4) * gap : 0
                        let addRowGap = (blockInterval == 1 || blockInterval == 3) ? CGFloat(row / 4) * gap : 0
                        
                        let x = offsetX + (size + gap) * CGFloat(col) + addColGap
                        let y = offsetY + (size + gap) * CGFloat(row) + addRowGap
                        let rect = CGRect(x: x, y: y, width: size, height: size)
                        
                        let path: Path
                        if pixelShape == 2 {
                            path = Path(ellipseIn: rect)
                        } else if pixelShape == 1 {
                            path = Path(rect)
                        } else {
                            path = Path(roundedRect: rect, cornerRadius: max(1.0, size * 0.15))
                        }
                        
                        if isBottomFilled {
                            ctx.fill(path, with: .color(bottomColor.opacity(0.85)))
                        } else if isTopFilled {
                            ctx.fill(path, with: .color(topColor.opacity(0.85)))
                        } else {
                            ctx.fill(path, with: .color(bottomColor.opacity(0.1)))
                        }
                    }
                }
            }
        }
        .frame(height: calculatedHeight)
    }
}

// MARK: - Network Matrix Card
struct NetMatrixCard: View {
    let downKBps: Double
    let upKBps: Double
    let downHistory: [Double]
    let upHistory: [Double]
    let symmetricGraph: Bool
    let chartPixelSize: Double
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5

    private let rows = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: "wifi")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan.opacity(0.8))
                Text("网络")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // ↓ 下行条形图
            PixelBarChartView(
                data: downHistory,
                maxRows: rows,
                baseColor: .cyan,
                gap: CGFloat(pixelGap),
                chartPixelSize: chartPixelSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // ↑ 上行条形图
            PixelBarChartView(
                data: upHistory,
                maxRows: rows,
                baseColor: .green,
                gap: CGFloat(pixelGap),
                invertY: symmetricGraph,
                chartPixelSize: chartPixelSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // 数值行
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down").font(.system(size: 7)).foregroundColor(.cyan)
                    Text(formatKBps(downKBps))
                        .font(.system(size: 9, design: .rounded).monospacedDigit())
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").font(.system(size: 7)).foregroundColor(.green)
                    Text(formatKBps(upKBps))
                        .font(.system(size: 9, design: .rounded).monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatKBps(_ kbps: Double) -> String {
        if kbps >= 1024 { return String(format: "%.1fM", kbps / 1024) }
        return String(format: "%.0fK", kbps)
    }
}

// MARK: - Disk Matrix Card
struct DiskMatrixCard: View {
    let readMBps: Double
    let writeMBps: Double
    let readHistory: [Double]
    let writeHistory: [Double]
    let symmetricGraph: Bool
    let chartPixelSize: Double
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5

    private let rows = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow.opacity(0.8))
                Text("磁盘")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // 读条形图
            PixelBarChartView(
                data: readHistory,
                maxRows: rows,
                baseColor: .yellow,
                gap: CGFloat(pixelGap),
                chartPixelSize: chartPixelSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // 写条形图
            PixelBarChartView(
                data: writeHistory,
                maxRows: rows,
                baseColor: .orange,
                gap: CGFloat(pixelGap),
                invertY: symmetricGraph,
                chartPixelSize: chartPixelSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // 数值行
            HStack(spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down").font(.system(size: 7)).foregroundColor(.yellow)
                    Text(formatMBps(readMBps))
                        .font(.system(size: 9, design: .rounded).monospacedDigit())
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").font(.system(size: 7)).foregroundColor(.orange)
                    Text(formatMBps(writeMBps))
                        .font(.system(size: 9, design: .rounded).monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatMBps(_ mbps: Double) -> String {
        if mbps < 0.05 { return "—" }
        return String(format: "%.1fM", mbps)
    }
}

// MARK: - Helpers
/// 把行优先的一维历史数组（时间从旧到新）转成列优先（左列=旧，右列=新）供像素矩阵用
private func columnMajor(_ data: [Double], rows: Int) -> [Double] {
    guard rows > 0, !data.isEmpty else { return data }
    let cols = Int(ceil(Double(data.count) / Double(rows)))
    var out = [Double](repeating: 0, count: cols * rows)
    for t in 0..<data.count {
        let col = t / rows
        let row = t % rows
        let idx = col * rows + row
        if idx < out.count { out[idx] = data[t] }
    }
    return out
}

// MARK: - Temperature Badge
struct TempBadgeView: View {
    let temp: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 10))
                .foregroundColor(tempColor)
            Text(String(format: "%.0f°C", temp))
                .font(.system(size: 11, design: .rounded).monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(tempColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tempColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var tempColor: Color {
        if temp > 90 { return .red }
        if temp > 75 { return .orange }
        return .secondary
    }
}

// MARK: - GPU Matrix Card
struct GPUMatrixCard: View {
    let utilization: Double
    let history: [Double]
    let heatmapSize: CGFloat
    let chartPixelSize: Double
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text("GPU")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary.opacity(0.7))
                Spacer()
                Text(String(format: "%.1f%%", utilization * 100))
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundColor(gpuColor)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Circle().fill(gpuColor).frame(width: 5, height: 5)
                    // a placeholder text to match CPU's "usr" label height
                    Text("渲染")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            // Faux heatmap matching CPU's P-cores width
            GPUHeatmapView(load: utilization, heatmapSize: heatmapSize)
            
            Spacer(minLength: 0)
            
            PixelBarChartView(
                data: history,
                maxRows: 8,
                baseColor: gpuColor,
                gap: CGFloat(pixelGap),
                chartPixelSize: chartPixelSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var gpuColor: Color {
        if utilization > 0.85 { return .red }
        if utilization > 0.5 { return .orange }
        return .indigo.opacity(0.8)
    }
}

struct GPUHeatmapView: View {
    let load: Double
    let heatmapSize: CGFloat
    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0
    
    var body: some View {
        // 与内存矩阵一致，使用高度为28的3行方格阵列来填满区域并完美对齐 CPU
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let cols = Int((geo.size.width + spacing) / (heatmapSize + spacing))
            let actualCols = max(cols, 1)
            
            let rows = Int((geo.size.height + spacing) / (heatmapSize + spacing))
            let actualRows = max(rows, 1)
            let c = actualCols * actualRows 
            
            let gridCols = Array(repeating: GridItem(.fixed(heatmapSize), spacing: spacing), count: actualCols)
            
            LazyVGrid(columns: gridCols, alignment: .leading, spacing: spacing) {
                ForEach(0..<c, id: \.self) { i in
                    let threshold = Double(i) / Double(c)
                    let loadRatio = load // GPU Utilization
                    let isActive = loadRatio > threshold
                    let fillCol = isActive ? Color.indigo.opacity(0.8) : Color.primary.opacity(0.09)
                    let strokeCol = isActive ? Color.indigo.opacity(0.3) : Color.clear
                    
                    Group {
                        if pixelShape == 2 {
                            Circle()
                                .fill(fillCol)
                                .overlay(Circle().stroke(strokeCol, lineWidth: 0.5))
                        } else if pixelShape == 1 {
                            Rectangle()
                                .fill(fillCol)
                                .overlay(Rectangle().stroke(strokeCol, lineWidth: 0.5))
                        } else {
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(fillCol)
                                .overlay(RoundedRectangle(cornerRadius: 1.5, style: .continuous).stroke(strokeCol, lineWidth: 0.5))
                        }
                    }
                    .frame(width: heatmapSize, height: heatmapSize)
                }
            }
            .drawingGroup()
        }
    }
}

// MARK: - Plugin Definition & Settings
struct SystemMonitorConfigView: View {
    @AppStorage("sysMonShowCompute") private var showCompute = true
    @AppStorage("sysMonShowMemory") private var showMemory = true
    @AppStorage("sysMonShowNetDisk") private var showNetDisk = true
    @AppStorage("sysMonSymmetricGraph") private var symmetricGraph = false
    @AppStorage("sysMonPixelGap") private var pixelGap: Double = 1.5
    @AppStorage("sysMonPixelShape") private var pixelShape: Int = 0
    @AppStorage("sysMonPixelDensity") private var pixelDensity: Double = 1.0
    @AppStorage("sysMonBlockInterval") private var blockInterval: Int = 0
    @AppStorage("sysMonChartPixelSize") private var chartPixelSize: Double = 5.0
    @AppStorage("sysMonHeatmapSize") private var heatmapSize: Double = 8.0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：独立的侧边栏式预览
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    SystemMonitorModule()
                        .frame(width: 400)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    Spacer(minLength: 0)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            
            // 右侧：偏好设置详情
            VStack(spacing: 0) {
                Form {
                    Section("显示模块") {
                        Toggle("计算 (CPU 与 GPU)", isOn: $showCompute)
                        Toggle("统一内存", isOn: $showMemory)
                        Toggle("网络与磁盘", isOn: $showNetDisk)
                    }
                    
                    Section("图表与尺寸") {
                        Picker("网络磁盘走势向", selection: $symmetricGraph) {
                            Text("正向堆叠").tag(false)
                            Text("双向发散").tag(true)
                        }
                        .pickerStyle(.menu)
                        
                        VStack(spacing: 6) {
                            HStack {
                                Text("走势图颗粒尺寸")
                                Spacer()
                                Text("\(String(format: "%.1f", chartPixelSize))pt").foregroundColor(.secondary)
                            }
                            Slider(value: $chartPixelSize, in: 2.0...10.0)
                        }
                        .padding(.vertical, 4)
                        
                        VStack(spacing: 6) {
                            HStack {
                                Text("热力方块尺寸")
                                Spacer()
                                Text("\(String(format: "%.1f", heatmapSize))pt").foregroundColor(.secondary)
                            }
                            Slider(value: $heatmapSize, in: 4.0...20.0)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("像素风格渲染") {
                        Picker("像素个体形态", selection: $pixelShape) {
                            Text("圆角矩阵").tag(0)
                            Text("锐利方块").tag(1)
                            Text("浑圆点阵").tag(2)
                        }
                        .pickerStyle(.menu)
                        
                        Picker("像素阵列间距", selection: $pixelGap) {
                            Text("紧密 (1.0)").tag(1.0)
                            Text("标准 (1.5)").tag(1.5)
                            Text("宽松 (2.5)").tag(2.5)
                        }
                        .pickerStyle(.menu)
                        
                        Picker("网格致密程度", selection: $pixelDensity) {
                            Text("稀疏 (x0.5)").tag(0.5)
                            Text("标准 (x1.0)").tag(1.0)
                            Text("致密 (x1.5)").tag(1.5)
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("分隔网格模式", selection: $blockInterval) {
                            Text("无分隔 (平滑)").tag(0)
                            Text("行分隔 (纵向)").tag(1)
                            Text("列分隔 (横向)").tag(2)
                            Text("行列开阵列").tag(3)
                        }
                        .pickerStyle(.menu)
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                
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

struct SystemMonitorPlugin: AppWidgetPlugin {
    let id = "systemMonitor"
    let name = "系统监控"
    let icon = "chart.xyaxis.line"
    let hasSettings = true
    
    @MainActor
    var contentView: AnyView {
        AnyView(SystemMonitorModule())
    }
    
    @MainActor
    var settingsView: AnyView {
        AnyView(SystemMonitorConfigView())
    }
}

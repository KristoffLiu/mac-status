import SwiftUI

// MARK: - Main Module
struct SystemMonitorModule: View {
    @ObservedObject var service = SystemMonitorService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Section Title ───────────────────────────────────────────────
            HStack {
                Label("系统监控", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if service.cpuTemperature > 1 {
                    TempBadgeView(temp: service.cpuTemperature)
                }
            }

            // ── 3x2 Grid Layout ──────────────────────────────────────────────
            VStack(spacing: 12) {
                // Row 1: Compute (CPU & GPU)
                HStack(alignment: .top, spacing: 8) {
                    // CPU Card
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Text("CPU")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.primary.opacity(0.7))
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
                        CPUHeatmapView(loads: service.coreLoads, pCoreCount: service.pCoreCount, eCoreCount: service.eCoreCount)
                        
                        Spacer(minLength: 0)
                        
                        // CPU历史走势方格矩阵
                        PixelBarChartView(
                            data: service.cpuHistory,
                            maxRows: 8,
                            baseColor: cpuTotalColor(service.cpuTotal),
                            gap: 1.5
                        )
                        .frame(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Divider().opacity(0.3)

                    // GPU Card
                    GPUMatrixCard(
                        utilization: service.gpuUtilization,
                        history: service.gpuHistory
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }

                Divider().opacity(0.4).padding(.horizontal, 8)

                // Row 2: Unified Memory
                UnifiedMemCard(
                    sysUsedGB: service.memUsedGB,
                    gpuUsedGB: service.gpuMemUsedGB,
                    totalGB: service.memTotalGB,
                    sysHistory: service.memHistory,
                    gpuHistory: service.gpuMemHistory,
                    pressure: service.memPressure
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Divider().opacity(0.4).padding(.horizontal, 8)

                // Row 3: Network & Disk
                HStack(alignment: .top, spacing: 8) {
                    NetMatrixCard(
                        downKBps:    service.netDownKBps,
                        upKBps:      service.netUpKBps,
                        downHistory: service.netDownHistory,
                        upHistory:   service.netUpHistory
                    )
                    .frame(maxWidth: .infinity, alignment: .top)

                    Divider().opacity(0.3)

                    DiskMatrixCard(
                        readMBps:     service.diskReadMBps,
                        writeMBps:    service.diskWriteMBps,
                        readHistory:  service.diskReadHistory,
                        writeHistory: service.diskWriteHistory
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
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
        return [GridItem(.adaptive(minimum: 8, maximum: 8), spacing: 2)]
    }

    private var pColumns: [GridItem] {
        return [GridItem(.adaptive(minimum: 14, maximum: 14), spacing: 2)]
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
                                .frame(width: 8, height: 8)
                        }
                    }
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
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: loads)
    }
}

struct HeatCell: View {
    let load: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(cellColor)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .stroke(cellColor.opacity(0.3), lineWidth: 0.5)
            )
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

    var body: some View {
        GeometryReader { geo in
            // 1. 我们基于高度决定单个正方形格子的尺寸
            let cellH = (geo.size.height - gap * CGFloat(max(maxRows - 1, 0))) / CGFloat(max(maxRows, 1))
            let size = cellH // 维持绝对的正方形视觉
            
            // 2. 算出现在这个宽度下能塞下多少列（向上取整，以确保左边缘被完填满）
            let maxCols = Int(ceil((geo.size.width + gap) / (size + gap)))
            let cols = maxCols > 0 ? maxCols : 1
            
            // 3. 从数据末尾（最新）往前取对应数量，不够则全取
            let visibleData = data.count > cols ? Array(data.suffix(cols)) : data
            let c = visibleData.count > 0 ? visibleData.count : 1
            
            // 居右偏移（确保最新的波形一直咬着右边缘，左侧超出部分由负的offsetX切除）
            let totalW = size * CGFloat(c) + gap * CGFloat(max(c - 1, 0))
            let totalH = size * CGFloat(maxRows) + gap * CGFloat(max(maxRows - 1, 0))
            let offsetX = geo.size.width - totalW
            let offsetY = (geo.size.height - totalH) / 2

            // 数据已经在 service 中归一化为 0.0~1.0，所以满载刻度固定为 1.0
            let maxVal = 1.0

            Canvas { ctx, _ in
                for col in 0..<c {
                    let v = visibleData[col]
                    // 根据相对比例决定亮起几个格子
                    let ratio = v / maxVal
                    let fillRows = Int(ceil(ratio * Double(maxRows))) // ceil 确保有一点数据就会亮一格
                    
                    for row in 0..<maxRows {
                        // Y轴倒置，底部是最大的 row 索引
                        let isFilled = (maxRows - 1 - row) < fillRows
                        
                        let x = offsetX + (size + gap) * CGFloat(col)
                        let y = offsetY + (size + gap) * CGFloat(row)
                        let rect = CGRect(x: x, y: y, width: size, height: size)
                        let path = Path(roundedRect: rect, cornerRadius: 1.0) 

                        if isFilled {
                            ctx.fill(path, with: .color(baseColor.opacity(0.85)))
                        } else {
                            ctx.fill(path, with: .color(baseColor.opacity(0.1)))
                        }
                    }
                }
            }
        }
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
                Image(systemName: "memorychip")
                    .font(.caption.weight(.bold))
                    .foregroundColor(pressureColor)
                Text("统一内存")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary.opacity(0.7))
                
                Spacer()
                
                // Detailed Breakdown
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Circle().fill(pressureColor).frame(width: 5, height: 5)
                        Text(String(format: "系统: %.1fGB", sysUsedGB))
                            .font(.system(size: 9, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 2) {
                        Circle().fill(Color.teal.opacity(0.8)).frame(width: 5, height: 5)
                        Text(String(format: "图形: %.1fGB", gpuUsedGB))
                            .font(.system(size: 9, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: "(共%.0fGB)", totalGB))
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.65))
                }
            }

            HStack(alignment: .top, spacing: 8) {
                // 左侧: 堆叠时序走势图
                StackedPixelBarChartView(
                    bottomData: sysHistory,
                    topData: gpuHistory,
                    maxRows: 11,
                    bottomColor: pressureColor,
                    topColor: .teal,
                    gap: 1.5
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Divider().opacity(0.3)
                
                // 右侧: 热力图阵列 (增加到 6 行)
                GeometryReader { geo in
                    let spacing: CGFloat = 2
                    let cellSize: CGFloat = 8
                    let cols = Int((geo.size.width + spacing) / (cellSize + spacing))
                    let actualCols = max(cols, 1)
                    let c = actualCols * 6 
                    let gridCols = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: actualCols)
                    
                    LazyVGrid(columns: gridCols, alignment: .leading, spacing: spacing) {
                        ForEach(0..<c, id: \.self) { i in
                            let threshold = Double(i) / Double(c)
                            let isSys = threshold < sysRatio
                            let isGpu = threshold >= sysRatio && threshold < (sysRatio + gpuRatio)
                            
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(isSys ? pressureColor.opacity(0.8) : (isGpu ? Color.teal.opacity(0.8) : Color.primary.opacity(0.09)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                        .stroke(isSys ? pressureColor.opacity(0.3) : (isGpu ? Color.teal.opacity(0.3) : Color.clear), lineWidth: 0.5)
                                )
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 58)
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
    
    var body: some View {
        GeometryReader { geo in
            let size = (geo.size.height - gap * CGFloat(max(maxRows - 1, 0))) / CGFloat(maxRows)
            let c = Int((geo.size.width + gap) / (size + gap))
            let actualCols = max(1, c)
            
            let bData = bottomData.suffix(actualCols)
            let tData = topData.suffix(actualCols)
            let bVisible = Array(repeating: 0.0, count: max(0, actualCols - bData.count)) + bData
            let tVisible = Array(repeating: 0.0, count: max(0, actualCols - tData.count)) + tData
            
            let totalW = size * CGFloat(actualCols) + gap * CGFloat(max(actualCols - 1, 0))
            let totalH = size * CGFloat(maxRows) + gap * CGFloat(max(maxRows - 1, 0))
            let offsetX = geo.size.width - totalW
            let offsetY = (geo.size.height - totalH) / 2
            
            let maxVal = 1.0 
            
            Canvas { ctx, _ in
                for col in 0..<actualCols {
                    let bRatio = bVisible[col] / maxVal
                    let tRatio = tVisible[col] / maxVal
                    
                    let bFillRows = Int(ceil(bRatio * Double(maxRows)))
                    let tFillRows = Int(ceil(tRatio * Double(maxRows)))
                    
                    for row in 0..<maxRows {
                        let isBottomFilled = (maxRows - 1 - row) < bFillRows
                        let isTopFilled = (maxRows - 1 - row) >= bFillRows && (maxRows - 1 - row) < (bFillRows + tFillRows)
                        
                        let x = offsetX + (size + gap) * CGFloat(col)
                        let y = offsetY + (size + gap) * CGFloat(row)
                        let rect = CGRect(x: x, y: y, width: size, height: size)
                        let path = Path(roundedRect: rect, cornerRadius: 1.0)
                        
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
    }
}

// MARK: - Network Matrix Card
struct NetMatrixCard: View {
    let downKBps: Double
    let upKBps: Double
    let downHistory: [Double]
    let upHistory: [Double]

    // 上下各 4 行 → 对应更密的矩阵，但我们的历史记录是60。
    // 如果上下各4行，则共8行。如果共用60历史，每部分60/4=15列。
    // 这里上行、下行各占3行（18历史？或者我们裁剪历史数组到 3*15=45 也可以，或者就缩短为30即可让列数为10）。
    // 这里保持渲染完整 60 个数据，各占用 4 行 × 15 列。
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
                maxRows: 5,
                baseColor: .cyan,
                gap: 1.5
            )
            .frame(height: 25)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // ↑ 上行条形图
            PixelBarChartView(
                data: upHistory,
                maxRows: 5,
                baseColor: .green,
                gap: 1.5
            )
            .frame(height: 25)
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

    // 跟网络同理，各占4行（4×15列=60记录）
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
                maxRows: 5,
                baseColor: .yellow,
                gap: 1.5
            )
            .frame(height: 25)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // 写条形图
            PixelBarChartView(
                data: writeHistory,
                maxRows: 5,
                baseColor: .orange,
                gap: 1.5
            )
            .frame(height: 25)
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
            GPUHeatmapView(load: utilization)
            
            Spacer(minLength: 0)
            
            PixelBarChartView(
                data: history,
                maxRows: 8,
                baseColor: gpuColor,
                gap: 1.5
            )
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
    
    private var gpuColor: Color {
        if utilization > 0.85 { return .red }
        if utilization > 0.5 { return .orange }
        return .indigo.opacity(0.8)
    }
}

struct GPUHeatmapView: View {
    let load: Double
    
    var body: some View {
        // 与内存矩阵一致，使用高度为28的3行方格阵列来填满区域并完美对齐 CPU
        GeometryReader { geo in
            let spacing: CGFloat = 2
            let cellSize: CGFloat = 8
            let cols = Int((geo.size.width + spacing) / (cellSize + spacing))
            let actualCols = max(cols, 1)
            let c = actualCols * 3 
            let gridCols = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: actualCols)
            
            LazyVGrid(columns: gridCols, alignment: .leading, spacing: spacing) {
                ForEach(0..<c, id: \.self) { i in
                    let threshold = Double(i) / Double(c)
                    let loadRatio = load // GPU Utilization
                    let isActive = loadRatio > threshold
                    
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        // 使用 HeatCell 的渲染逻辑或自定义的主题色
                        .fill(isActive ? Color.indigo.opacity(0.8) : Color.primary.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .stroke(isActive ? Color.indigo.opacity(0.3) : Color.clear, lineWidth: 0.5)
                        )
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .frame(height: 28) // 精准锁定高度，与 CPU/内存 齐平
    }
}



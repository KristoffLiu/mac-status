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
            .padding(.horizontal, 4)

            // ── CPU Section ─────────────────────────────────────────────────
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

                    HStack(spacing: 2) {
                        Circle().fill(Color.blue.opacity(0.8)).frame(width: 5, height: 5)
                        Text(String(format: "%.1f%%", service.cpuUser * 100))
                            .font(.system(size: 10, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("usr")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    HStack(spacing: 2) {
                        Circle().fill(Color.orange.opacity(0.8)).frame(width: 5, height: 5)
                        Text(String(format: "%.1f%%", service.cpuSystem * 100))
                            .font(.system(size: 10, design: .rounded).monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("sys")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.horizontal, 4)

                // ✅ 正方形热力图
                CPUHeatmapView(loads: service.coreLoads)
            }

            Divider().opacity(0.4).padding(.horizontal, 8)

            // ── Memory + Network + Disk Row（像素矩阵）──────────────────────
            HStack(alignment: .top, spacing: 0) {
                MemMatrixCard(
                    usedGB:   service.memUsedGB,
                    totalGB:  service.memTotalGB,
                    pressure: service.memPressure,
                    history:  service.memHistory
                )

                Divider().frame(height: 68).opacity(0.3)

                NetMatrixCard(
                    downKBps:    service.netDownKBps,
                    upKBps:      service.netUpKBps,
                    downHistory: service.netDownHistory,
                    upHistory:   service.netUpHistory
                )

                Divider().frame(height: 68).opacity(0.3)

                DiskMatrixCard(
                    readMBps:     service.diskReadMBps,
                    writeMBps:    service.diskWriteMBps,
                    readHistory:  service.diskReadHistory,
                    writeHistory: service.diskWriteHistory
                )
            }
            .padding(.horizontal, 4)
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

    private var columns: [GridItem] {
        let cols = min(loads.count, loads.count > 8 ? 10 : 8)
        return Array(repeating: GridItem(.flexible(), spacing: 3), count: cols)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<loads.count, id: \.self) { i in
                HeatCell(load: loads[i])
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: loads)
    }
}

struct HeatCell: View {
    let load: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(cellColor)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .stroke(cellColor.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: load > 0.75 ? cellColor.opacity(0.55) : .clear, radius: 2.5)
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

// MARK: - 通用像素矩阵视图（时序热力图）
/// rows × cols 的小色块网格，data 是按时间先后排列的归一化数组（0.0~1.0）
/// 最新数据在右侧，旧的在左侧
struct PixelMatrixView: View {
    let data: [Double]         // 长度 = rows * cols，按列优先（时间从左到右）
    let rows: Int
    let baseColor: Color
    let gap: CGFloat

    private var cols: Int { data.count / max(rows, 1) }

    var body: some View {
        GeometryReader { geo in
            let c = cols
            let cellW = (geo.size.width  - gap * CGFloat(c - 1)) / CGFloat(c)
            let cellH = (geo.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

            Canvas { ctx, size in
                for col in 0..<c {
                    for row in 0..<rows {
                        let idx = col * rows + row
                        guard idx < data.count else { continue }
                        let v = data[idx]
                        let x = (cellW + gap) * CGFloat(col)
                        let y = (cellH + gap) * CGFloat(row)
                        let rect = CGRect(x: x, y: y, width: cellW, height: cellH)
                        let path = Path(roundedRect: rect, cornerRadius: 1.5)

                        // 颜色：越高越亮
                        let opacity = 0.07 + v * 0.88
                        ctx.fill(path, with: .color(baseColor.opacity(opacity)))
                    }
                }
            }
        }
    }
}

// MARK: - Memory Matrix Card
struct MemMatrixCard: View {
    let usedGB: Double
    let totalGB: Double
    let pressure: Double
    let history: [Double]   // 60 帧

    // 显示为 4 行 × 15 列的像素矩阵
    private let rows = 4
    private var matrixData: [Double] {
        // 把 60 个连续帧拆成列优先（4行×15列）
        history
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题行
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                    .font(.system(size: 9))
                    .foregroundColor(.purple.opacity(0.8))
                Text("内存")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f GB", usedGB))
                    .font(.system(size: 10, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(pressureColor)
            }

            // 像素矩阵
            PixelMatrixView(
                data: columnMajor(history, rows: rows),
                rows: rows,
                baseColor: .purple,
                gap: 1.5
            )
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // 底部数值
            HStack(spacing: 0) {
                Text(String(format: "%.0f%%", pressure * 100))
                    .font(.system(size: 9, design: .rounded).monospacedDigit())
                    .foregroundColor(pressureColor)
                Text(" / \(Int(totalGB))GB")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private var pressureColor: Color {
        if pressure > 0.85 { return .red }
        if pressure > 0.65 { return .orange }
        return .purple.opacity(0.9)
    }
}

// MARK: - Network Matrix Card
struct NetMatrixCard: View {
    let downKBps: Double
    let upKBps: Double
    let downHistory: [Double]
    let upHistory: [Double]

    private let rows = 2   // 上下各 2 行 → 总共显示 ↓ 和 ↑

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "wifi")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan.opacity(0.8))
                Text("网络")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // ↓ 下行矩阵
            PixelMatrixView(
                data: columnMajor(downHistory, rows: rows),
                rows: rows,
                baseColor: .cyan,
                gap: 1.5
            )
            .frame(height: 11)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // ↑ 上行矩阵
            PixelMatrixView(
                data: columnMajor(upHistory, rows: rows),
                rows: rows,
                baseColor: .green,
                gap: 1.5
            )
            .frame(height: 11)
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
        .padding(.horizontal, 6)
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

    private let rows = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow.opacity(0.8))
                Text("磁盘")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // 读矩阵
            PixelMatrixView(
                data: columnMajor(readHistory, rows: rows),
                rows: rows,
                baseColor: .yellow,
                gap: 1.5
            )
            .frame(height: 11)
            .clipShape(RoundedRectangle(cornerRadius: 2))

            // 写矩阵
            PixelMatrixView(
                data: columnMajor(writeHistory, rows: rows),
                rows: rows,
                baseColor: .orange,
                gap: 1.5
            )
            .frame(height: 11)
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
        .padding(.horizontal, 6)
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

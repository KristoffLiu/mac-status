import SwiftUI

// MARK: - Main Module
struct SystemMonitorModule: View {
    @ObservedObject var service = SystemMonitorService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // ── Section Title ──────────────────────────────────────────────
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

            // ── CPU Section ────────────────────────────────────────────────
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

                // Heatmap Grid
                CPUHeatmapView(loads: service.coreLoads)
            }

            Divider().opacity(0.4).padding(.horizontal, 8)

            // ── Memory + Network + Disk Row ────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                MemoryMiniCard(usedGB: service.memUsedGB,
                               totalGB: service.memTotalGB,
                               cachedGB: service.memCachedGB,
                               pressure: service.memPressure)
                
                Divider().frame(height: 52).opacity(0.3)
                
                NetMiniCard(downKBps: service.netDownKBps, upKBps: service.netUpKBps)
                
                Divider().frame(height: 52).opacity(0.3)
                
                DiskMiniCard(readMBps: service.diskReadMBps, writeMBps: service.diskWriteMBps)
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

// MARK: - CPU Heatmap
struct CPUHeatmapView: View {
    let loads: [Double]

    private var columns: [GridItem] {
        // Aim for ~8 columns max; wrap if more cores
        let cols = min(loads.count, loads.count > 8 ? 10 : 8)
        return Array(repeating: GridItem(.flexible(), spacing: 3), count: cols)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<loads.count, id: \.self) { i in
                HeatCell(load: loads[i])
                    .frame(height: 14)
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
            .shadow(color: load > 0.75 ? cellColor.opacity(0.5) : .clear, radius: 2)
    }

    private var cellColor: Color {
        switch load {
        case ..<0.08: return Color.primary.opacity(0.09)
        case 0.08..<0.3: return Color(hue: 0.35, saturation: 0.8, brightness: 0.7).opacity(0.55 + load * 0.8)
        case 0.3..<0.65: return Color(hue: 0.12, saturation: 0.9, brightness: 0.9).opacity(0.75)
        case 0.65..<0.85: return Color(hue: 0.05, saturation: 1.0, brightness: 1.0).opacity(0.85)
        default:           return Color.red.opacity(0.9)
        }
    }
}

// MARK: - Memory Mini Card
struct MemoryMiniCard: View {
    let usedGB: Double
    let totalGB: Double
    let cachedGB: Double
    let pressure: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                    .font(.system(size: 9))
                    .foregroundColor(.purple.opacity(0.8))
                Text("内存")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Text(String(format: "%.1f / %.0f GB", usedGB, totalGB))
                .font(.system(size: 12, design: .rounded).monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(pressureColor)

            // Tiny bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(pressureColor.opacity(0.8))
                        .frame(width: geo.size.width * min(1, pressure))
                        .animation(.easeInOut(duration: 0.4), value: pressure)
                }
            }
            .frame(height: 4)

            Text(String(format: "缓存 %.1fGB", cachedGB))
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
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

// MARK: - Network Mini Card
struct NetMiniCard: View {
    let downKBps: Double
    let upKBps: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "wifi")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan.opacity(0.8))
                Text("网络")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 3) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8))
                    .foregroundColor(.cyan)
                Text(formatKBps(downKBps))
                    .font(.system(size: 12, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8))
                    .foregroundColor(.green.opacity(0.8))
                Text(formatKBps(upKBps))
                    .font(.system(size: 12, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Text("实时吞吐")
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private func formatKBps(_ kbps: Double) -> String {
        if kbps >= 1024 { return String(format: "%.1f MB/s", kbps / 1024) }
        return String(format: "%.0f KB/s", kbps)
    }
}

// MARK: - Disk Mini Card
struct DiskMiniCard: View {
    let readMBps: Double
    let writeMBps: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow.opacity(0.8))
                Text("磁盘")
                    .font(.system(size: 10).weight(.semibold))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 3) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8))
                    .foregroundColor(.cyan)
                Text(formatMBps(readMBps))
                    .font(.system(size: 12, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow.opacity(0.9))
                Text(formatMBps(writeMBps))
                    .font(.system(size: 12, design: .rounded).monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Text("读 / 写速度")
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
    }

    private func formatMBps(_ mbps: Double) -> String {
        if mbps < 0.1 { return "— MB/s" }
        return String(format: "%.1f MB/s", mbps)
    }
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

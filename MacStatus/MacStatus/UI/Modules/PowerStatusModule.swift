import SwiftUI

struct PowerStatusModule: View {
    var batteryData: BatteryData
    var powerFlow: PowerFlowData

    // MARK: - Computed helpers

    private var chargeState: ChargeState {
        if powerFlow.isCharging { return .charging }
        if powerFlow.adapterPower > 0 { return .bypass }
        return .discharging
    }

    enum ChargeState {
        case charging, bypass, discharging

        var label: String {
            switch self {
            case .charging:    return "充电中"
            case .bypass:      return "旁路供电"
            case .discharging: return "电池放电"
            }
        }

        var icon: String {
            switch self {
            case .charging:    return "bolt.fill"
            case .bypass:      return "powerplug.fill"
            case .discharging: return "battery.75"
            }
        }

        var color: Color {
            switch self {
            case .charging:    return .green
            case .bypass:      return Color(hue: 0.6, saturation: 0.7, brightness: 0.9)
            case .discharging: return .orange
            }
        }
    }

    private var capacityColor: Color {
        let pct = batteryData.currentCapacity
        if pct > 50 { return .green }
        if pct > 20 { return .orange }
        return .red
    }

    private var timeRemainingText: String {
        guard let t = batteryData.timeRemaining, t > 0, t < 1000 else {
            return chargeState == .bypass ? "以电源供电" : "预估中…"
        }
        let h = t / 60, m = t % 60
        let prefix = powerFlow.isCharging ? "充满还需" : "可续航"
        return "\(prefix) \(h)h \(m)m"
    }

    // Active Voltage: Use Adapter's hardware voltage when connected and supplying power, otherwise fallback to Battery cell voltage.
    private var displayVolts: Double {
        if powerFlow.adapterPower > 0 {
            if let smcVolts = powerFlow.adapterVoltage, smcVolts > 0 {
                return smcVolts
            } else if let adapter = batteryData.adapter, let profile = adapter.activeProfile, profile.maxVoltage > 0 {
                return profile.maxVoltage // Fallback to negotiated static maximum
            }
        }
        return Double(batteryData.voltage) / 1000.0
    }

    // Active Amperage: Rather than relying on slow polling IOKit amperage (updates only every 2s),
    // derive the instantaneous real-time current matching our 10 FPS SMC power telemetry!
    // Or if Apple Silicon SMC gives us ID0R directly, use it for the highest hardware precision.
    private var displayAmps: Double {
        if powerFlow.adapterPower > 0, let smcAmps = powerFlow.adapterCurrent, smcAmps > 0 {
            return smcAmps
        }
        
        let volts = displayVolts > 0.1 ? displayVolts : 11.4
        
        if powerFlow.adapterPower > 0 {
            // Fallback: A = W / V matching the powerFlow animation
            return powerFlow.adapterPower / volts
        } else if powerFlow.isDischarging {
            // Unplugged: systemPower (real-time SMC constraint) perfectly describes the battery's real-time discharge.
            return powerFlow.systemPower / volts
        }
        
        return abs(Double(batteryData.amperage) / 1000.0)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header row ────────────────────────────────────────────
            headerRow

            // ── Three power cards ─────────────────────────────────────
            powerCardsRow

            // ── Bottom detail row ─────────────────────────────────────
            detailRow
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack(spacing: 8) {
            // State badge
            HStack(spacing: 5) {
                Image(systemName: chargeState.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(chargeState.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(chargeState.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(chargeState.color.opacity(0.15))
            )

            Spacer()

            // Adapter name or battery-only label
            if let adapter = batteryData.adapter {
                Text(adapter.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("内置电池")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var powerCardsRow: some View {
        HStack(spacing: 8) {
            // Adapter
            PowerCard(
                title: "适配器",
                icon: "powerplug.fill",
                value: powerFlow.adapterPower > 0
                    ? String(format: "%.1fW", powerFlow.adapterPower) : "--",
                color: Color(hue: 0.6, saturation: 0.75, brightness: 0.9),
                isActive: powerFlow.adapterPower > 0.1
            )

            // Arrow
            Image(systemName: powerFlow.isCharging ? "arrow.right.arrow.left" : "arrow.right")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))

            // System
            PowerCard(
                title: "系统",
                icon: "laptopcomputer",
                value: powerFlow.systemPower > 0
                    ? String(format: "%.1fW", powerFlow.systemPower) : "--",
                color: .primary,
                isActive: powerFlow.systemPower > 0.1
            )

            // Arrow
            Image(systemName: powerFlow.isDischarging ? "arrow.left" : "arrow.right")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))

            // Battery
            PowerCard(
                title: "电池",
                icon: powerFlow.isCharging ? "battery.100.bolt" : "battery.75",
                value: powerFlow.batteryPower > 0.1
                    ? String(format: "%.1fW", powerFlow.batteryPower) : "待机",
                color: powerFlow.isCharging ? .green : (powerFlow.isDischarging ? .orange : .secondary),
                isActive: powerFlow.batteryPower > 0.1
            )
        }
        .padding(.horizontal, 4)
    }

    private var detailRow: some View {
        VStack(spacing: 8) {
            // Voltage / Current / Capacity
            HStack(spacing: 0) {
                miniDetailItem(
                    label: "电压",
                    value: String(format: "%.2fV", displayVolts)
                )
                Divider().frame(height: 24)
                miniDetailItem(
                    label: "电流",
                    value: String(format: "%.2fA", displayAmps)
                )
                Divider().frame(height: 24)
                miniDetailItem(
                    label: "电量",
                    value: "\(batteryData.currentCapacity)%",
                    valueColor: capacityColor
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )

            // Capacity bar + time remaining
            HStack(spacing: 10) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [capacityColor.opacity(0.7), capacityColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(batteryData.currentCapacity) / 100.0)
                            .animation(.easeInOut(duration: 0.6), value: batteryData.currentCapacity)
                    }
                }
                .frame(height: 6)

                // Time
                Text(timeRemainingText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 4)
    }

    private func miniDetailItem(label: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundColor(valueColor)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - PowerCard

private struct PowerCard: View {
    var title: String
    var icon: String
    var value: String
    var color: Color
    var isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(isActive ? color : .secondary.opacity(0.4))
                .frame(height: 20)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(isActive ? color : .secondary.opacity(0.5))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isActive ? color.opacity(0.25) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

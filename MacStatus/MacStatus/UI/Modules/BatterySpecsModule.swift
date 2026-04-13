import SwiftUI

struct BatterySpecsModule: View {
    var batteryData: BatteryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电池规格")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            HStack {
                // System load purely from battery PMU
                let volts = Double(batteryData.voltage) / 1000.0
                let amps = Double(batteryData.amperage) / 1000.0
                let batteryWatts = abs(volts * amps)
                detailItem(title: "电池供流负载 (Load)", value: String(format: "%.2f W", batteryWatts))
                Spacer()
                detailItem(title: "内部温度", value: String(format: "%.1f°C", batteryData.temperature))
            }
            .padding(.horizontal, 4)
            
            HStack {
                detailItem(title: "输出电压", value: String(format: "%.2f V", Double(batteryData.voltage) / 1000.0))
                Spacer()
                detailItem(title: "输出电流", value: String(format: "%.2f A", abs(Double(batteryData.amperage) / 1000.0)))
            }
            .padding(.horizontal, 4)
            
            if let adapter = batteryData.adapter, let profile = adapter.activeProfile {
                Divider()
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                
                HStack {
                    detailItem(title: "硬件适配器协议", value: String(format: "%.1fV / %.1fA", profile.maxVoltage, profile.maxCurrent), width: 140)
                    Spacer()
                    detailItem(title: "最高握手功率", value: String(format: "%.1f W", profile.maxWatts))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
    
    private func detailItem(title: String, value: String, width: CGFloat = 140) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: width, alignment: .leading)
    }
}

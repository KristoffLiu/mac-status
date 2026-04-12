import SwiftUI

struct DetailGridModule: View {
    var batteryData: BatteryData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                detailItem(title: "Capacity", value: "\(batteryData.currentCapacity)%")
                Spacer()
                detailItem(title: "Health", value: "\(calculateHealth())%")
            }
            HStack {
                detailItem(title: "Cycles", value: "\(batteryData.cycleCount)")
                Spacer()
                detailItem(title: "Temperature", value: String(format: "%.1f°C", batteryData.temperature))
            }
            HStack {
                detailItem(title: "Voltage", value: "\(batteryData.voltage) mV")
                Spacer()
                detailItem(title: "Amperage", value: "\(batteryData.amperage) mA")
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, batteryData.adapter != nil ? 0 : 8)
        
        if let adapter = batteryData.adapter {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .padding(.horizontal, 4)
                
                Text("充电协议 (Adapter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                HStack {
                    detailItem(title: "Design Max", value: "\(adapter.designWatts) W", width: 80)
                    Spacer()
                    if let profile = adapter.activeProfile {
                        detailItem(title: "Active PD", value: String(format: "%.1fV / %.1fA", profile.maxVoltage, profile.maxCurrent), width: 120)
                    } else {
                        detailItem(title: "Protocol", value: adapter.name, width: 120)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.bottom, 8)
        }
    }
    
    private func detailItem(title: String, value: String, width: CGFloat = 100) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .fontWeight(.medium)
        }
        .frame(width: width, alignment: .leading)
    }
    
    private func calculateHealth() -> Int {
        guard batteryData.designCapacity > 0 else { return 100 }
        let health = Double(batteryData.maxCapacity) / Double(batteryData.designCapacity) * 100
        return Int(min(100.0, health))
    }
}

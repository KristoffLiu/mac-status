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
        .padding(.vertical, 8)
    }
    
    private func detailItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .fontWeight(.medium)
        }
        .frame(width: 100, alignment: .leading)
    }
    
    private func calculateHealth() -> Int {
        guard batteryData.designCapacity > 0 else { return 100 }
        let health = Double(batteryData.maxCapacity) / Double(batteryData.designCapacity) * 100
        return Int(min(100.0, health))
    }
}

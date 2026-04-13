import SwiftUI

struct BatteryHealthModule: View {
    var batteryData: BatteryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电池健康")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            HStack {
                let healthPercent = calculateHealth()
                detailItem(title: "硬件健康度", value: "\(healthPercent)%")
                Spacer()
                let condition = healthPercent > 80 ? "状态良好" : (healthPercent > 50 ? "建议维修" : "需要更换")
                detailItem(title: "系统状态评估", value: condition)
            }
            
            HStack {
                detailItem(title: "当前最大容量", value: "\(batteryData.maxCapacity) mAh")
                Spacer()
                detailItem(title: "出厂设计容量", value: "\(batteryData.designCapacity) mAh")
            }
            
            HStack {
                detailItem(title: "循环次数 (Cycles)", value: "\(batteryData.cycleCount) 次")
                Spacer()
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
    
    private func calculateHealth() -> Int {
        guard batteryData.designCapacity > 0 else { return 100 }
        let health = Double(batteryData.maxCapacity) / Double(batteryData.designCapacity) * 100
        return Int(min(100.0, max(0.0, health)))
    }
}

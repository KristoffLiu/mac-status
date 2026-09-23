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
                let healthPercent = batteryData.healthPercent
                detailItem(title: "硬件健康度", value: healthPercent.map { "\($0)%" } ?? "—")
                Spacer()
                let condition = healthPercent.map { $0 > 80 ? "容量正常" : "容量偏低" } ?? "暂不可用"
                detailItem(title: "容量评估（非系统诊断）", value: condition)
            }
            
            HStack {
                detailItem(title: "当前最大容量", value: batteryData.maxCapacity > 100 ? "\(batteryData.maxCapacity) mAh" : "—")
                Spacer()
                detailItem(title: "出厂设计容量", value: batteryData.designCapacity > 100 ? "\(batteryData.designCapacity) mAh" : "—")
            }
            
            HStack {
                detailItem(title: "循环次数 (Cycles)", value: batteryData.isAvailable ? "\(batteryData.cycleCount) 次" : "—")
                Spacer()
            }
        }
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

import SwiftUI

struct PowerStatusModule: View {
    var batteryData: BatteryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电源状态")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                
            HStack {
                // Fixed: currentCapacity is physically mapped securely
                detailItem(title: "当前系统电量", value: "\(batteryData.currentCapacity)%")
                Spacer()
                let stateStr = batteryData.isCharging ? "充电中" : (batteryData.adapterWatts > 0 ? "电源受电/旁路" : "放电中")
                detailItem(title: "电源状态", value: stateStr)
            }
            .padding(.horizontal, 4)
            
            HStack {
                if let timeRemaining = batteryData.timeRemaining, timeRemaining > 0, timeRemaining < 1000 {
                    let hours = timeRemaining / 60
                    let mins = timeRemaining % 60
                    let prefix = batteryData.isCharging ? "充满还需" : "剩余可用"
                    detailItem(title: "预估时间", value: "\(prefix) \(hours)h \(mins)m")
                } else if batteryData.isCharging {
                    detailItem(title: "预估时间", value: "预估计算中...")
                } else if batteryData.adapterWatts > 0 {
                    detailItem(title: "预估时间", value: "以电源供电中")
                } else {
                    detailItem(title: "预估时间", value: "预估计算中...")
                }
                Spacer()
                
                if let adapter = batteryData.adapter {
                    detailItem(title: "供电来源", value: "\(adapter.name) (\(adapter.designWatts)W)")
                } else {
                    detailItem(title: "供电来源", value: "内置电池")
                }
            }
            .padding(.horizontal, 4)
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

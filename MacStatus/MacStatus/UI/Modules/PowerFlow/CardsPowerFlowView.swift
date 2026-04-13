import SwiftUI

struct CardsPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Bar
            HStack {
                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text(statusText)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
                
                if powerFlow.adapterPower > 2 {
                    Text(adapterName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            // 3 Cards Layout
            HStack(spacing: 8) {
                // Adapter Card
                let hasAdapter = powerFlow.adapterPower > 2
                let adapterV = powerFlow.adapterVoltage ?? (batteryData?.adapter?.voltage ?? 0)
                let adapterA = powerFlow.adapterCurrent ?? (batteryData?.adapter?.current ?? 0)
                
                let adapterDetails: [String] = {
                    if hasAdapter {
                        var details = [String(format: "实测: %.2fV %.2fA", adapterV, adapterA)]
                        if let adapter = batteryData?.adapter {
                            details.append("峰值: \(adapter.designWatts)W")
                            if let pd = adapter.activeProfile {
                                details.append("协议: \(Int(pd.maxVoltage))V/\(Int(pd.maxCurrent))A")
                            }
                            details.append("FmCode: \(adapter.familyCode)")
                        }
                        return details
                    }
                    return []
                }()
                
                card(icon: "powerplug.fill", 
                     title: "适配器", 
                     power: hasAdapter ? powerFlow.adapterPower : -1, 
                     color: (hasAdapter && !powerFlow.isDischarging) ? .blue : .secondary.opacity(0.5), 
                     details: adapterDetails)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(hasAdapter && !powerFlow.isDischarging ? .gray.opacity(0.5) : .gray.opacity(0.2))
                    .font(.system(size: 14, weight: .bold))
                
                // System Card
                card(icon: "laptopcomputer", 
                     title: "系统", 
                     power: powerFlow.systemPower, 
                     color: .primary, 
                     details: [])
                
                let arrowColor: Color = powerFlow.isCharging ? .green.opacity(0.7) : (powerFlow.isDischarging ? .blue.opacity(0.7) : .gray.opacity(0.2))
                let arrowIcon = powerFlow.isDischarging ? "arrow.left" : "arrow.right"
                
                Image(systemName: arrowIcon)
                    .foregroundColor(arrowColor)
                    .font(.system(size: 14, weight: .bold))
                
                // Battery Card
                let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                let batPowerValue = (powerFlow.isCharging || powerFlow.isDischarging) ? powerFlow.batteryPower : nil
                card(icon: powerFlow.isCharging ? "battery.100.bolt" : "battery.100", 
                     title: "电池", 
                     power: batPowerValue,
                     color: powerFlow.isDischarging ? .blue : (powerFlow.isCharging ? .green : .secondary),
                     details: ["\(batteryData?.currentCapacity ?? 0)%", "\(String(format: "%.1fV", batV)) \(String(format: "%.2fA", abs(batA)))"])
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func card(icon: String, title: String, power: Double?, color: Color, details: [String]) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .medium))
                .padding(.bottom, 4)
            
            if let p = power, p >= 0 {
                Text(String(format: "%.1fW", p))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color == .secondary ? .primary : color)
            } else if title == "电池" && power == nil {
                Text("待机")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            
            if !details.isEmpty {
                VStack(spacing: 2) {
                    ForEach(details, id: \.self) { text in
                        Text(text)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var statusText: String {
        if powerFlow.isCharging { return "电池充电" }
        if powerFlow.isDischarging { return "电池供电" }
        if powerFlow.adapterPower > 2 { return "旁路供电" }
        return "电池闲置"
    }
    
    private var adapterName: String {
        return batteryData?.adapter?.name ?? "pd charger"
    }
}

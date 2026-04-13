import SwiftUI

struct CardsPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    @State private var isExpanded: Bool = false
    @State private var focusedCard: Int? = nil
    
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
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: isExpanded ? 8 : -60) {
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
                    .zIndex(3)
                    .id(1)
                    .onTapGesture { handleTap(1, proxy: proxy) }
                
                if isExpanded {
                    Image(systemName: "arrow.right")
                        .foregroundColor(hasAdapter && !powerFlow.isDischarging ? .gray.opacity(0.5) : .gray.opacity(0.2))
                        .font(.system(size: 14, weight: .bold))
                }
                
                // System Card
                card(icon: "laptopcomputer", 
                     title: "系统", 
                     power: powerFlow.systemPower, 
                     color: .primary, 
                     details: [])
                    .zIndex(2)
                    .id(2)
                    .onTapGesture { handleTap(2, proxy: proxy) }
                
                let arrowColor: Color = powerFlow.isCharging ? .green.opacity(0.7) : (powerFlow.isDischarging ? .blue.opacity(0.7) : .gray.opacity(0.2))
                let arrowIcon = powerFlow.isDischarging ? "arrow.left" : "arrow.right"
                
                if isExpanded {
                    Image(systemName: arrowIcon)
                        .foregroundColor(arrowColor)
                        .font(.system(size: 14, weight: .bold))
                }
                
                // Battery Card
                let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                let batPowerValue = (powerFlow.isCharging || powerFlow.isDischarging) ? powerFlow.batteryPower : nil
                card(icon: powerFlow.isCharging ? "battery.100.bolt" : "battery.100", 
                     title: "电池", 
                     power: batPowerValue,
                     color: powerFlow.isDischarging ? .blue : (powerFlow.isCharging ? .green : .secondary),
                      details: ["\(batteryData?.currentCapacity ?? 0)%", "\(String(format: "%.1fV", batV)) \(String(format: "%.2fA", abs(batA)))"])
                    .zIndex(1)
                    .id(3)
                    .onTapGesture { handleTap(3, proxy: proxy) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        }
        .padding(.horizontal, -20)
    }
    .padding(.vertical, 8)
}

    private func handleTap(_ id: Int, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if isExpanded && focusedCard == id {
                isExpanded = false
                focusedCard = nil
            } else {
                isExpanded = true
                focusedCard = id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func card(icon: String, title: String, power: Double?, color: Color, details: [String]) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 2) {
                // Top row layout
                // Left: Big wattage
                if let p = power, p >= 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", p))
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(color == .secondary ? .primary : color)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("W")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                } else if title == "电池" && power == nil {
                    Text("待机")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                } else {
                    Text("--")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.3))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.9))
                    .padding(.top, 4)
                
                // Details List
                if !details.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(details, id: \.self) { text in
                            Text(text)
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Right: Icon Badge
            Image(systemName: icon)
                .foregroundColor(color == .secondary ? .primary : color)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 28, height: 28)
                .background((color == .secondary ? Color.primary : color).opacity(0.1))
                .clipShape(Circle())
        }
        .padding(14)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
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

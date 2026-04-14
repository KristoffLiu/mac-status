import SwiftUI

struct CardsPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    @State private var isExpanded: Bool = false
    @State private var focusedCard: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var savedOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 6) {
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
            .padding(.horizontal, 12)
            
            // 3/2 Cards Layout, Custom Carousel
            ZStack {
                let hasAdapter = powerFlow.adapterPower > 2
                
                // Card 1: Adapter (if hasAdapter) OR Battery Output (if pure battery)
                if hasAdapter {
                    let adapterV = powerFlow.adapterVoltage ?? (batteryData?.adapter?.voltage ?? 0)
                    let adapterA = powerFlow.adapterCurrent ?? (batteryData?.adapter?.current ?? 0)
                    
                    let adapterDetails: [String] = {
                        var details = [String(format: "实测: %.2fV %.2fA", adapterV, adapterA)]
                        if let adapter = batteryData?.adapter {
                            details.append("峰值: \(adapter.designWatts)W")
                            if let pd = adapter.activeProfile {
                                let vStr = pd.maxVoltage.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", pd.maxVoltage) : String(format: "%.1f", pd.maxVoltage)
                                let cStr = pd.maxCurrent.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", pd.maxCurrent) : String(format: "%.2f", pd.maxCurrent)
                                details.append("协议: \(vStr)V/\(cStr)A")
                            }
                            if let mfg = adapter.manufacturer, !mfg.isEmpty {
                                details.append("厂商: \(mfg)")
                            }
                            details.append("FmCode: \(adapter.familyCode)")
                        }
                        return details
                    }()
                    
                    card(icon: "powerplug.fill", 
                         title: batteryData?.adapter?.name ?? "适配器", 
                         power: powerFlow.adapterPower, 
                         color: !powerFlow.isDischarging ? .blue : .secondary.opacity(0.5), 
                         details: adapterDetails)
                        .offset(x: isExpanded ? -180 : -110)
                        .zIndex(3)
                        .id(1)
                        .onTapGesture { handleTap(1) }
                } else {
                    let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                    let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                    card(icon: "battery.100.bolt",
                         title: "电池输出",
                         power: powerFlow.batteryPower,
                         color: .blue, // Act as the main source, blue indicates standard power flow
                         details: ["\(batteryData?.currentCapacity ?? 0)% 余量", String(format: "实测: %.1fV %.2fA", batV, abs(batA))])
                        .offset(x: isExpanded ? -180 : -110)
                        .zIndex(3)
                        .id(1)
                        .onTapGesture { handleTap(1) }
                }
                
                if isExpanded {
                    Image(systemName: "arrow.right")
                        .foregroundColor(hasAdapter && !powerFlow.isDischarging ? .gray.opacity(0.5) : (!hasAdapter ? .blue.opacity(0.7) : .gray.opacity(0.2)))
                        .font(.system(size: 14, weight: .bold))
                        .offset(x: -90)
                }
                
                // Card 2: System Card
                card(icon: "laptopcomputer", 
                     title: "系统", 
                     power: powerFlow.systemPower, 
                     color: .primary, 
                     details: [])
                    .offset(x: 0)
                    .zIndex(2)
                    .id(2)
                    .onTapGesture { handleTap(2) }
                
                // Card 3: Battery Card (Only present if adapter is connected)
                if hasAdapter {
                    let arrowColor: Color = powerFlow.isCharging ? .green.opacity(0.7) : (powerFlow.isDischarging ? .blue.opacity(0.7) : .gray.opacity(0.2))
                    let arrowIcon = powerFlow.isDischarging ? "arrow.left" : "arrow.right"
                    
                    if isExpanded {
                        Image(systemName: arrowIcon)
                            .foregroundColor(arrowColor)
                            .font(.system(size: 14, weight: .bold))
                            .offset(x: 90)
                    }
                    
                    let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                    let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                    let batPowerValue = (powerFlow.isCharging || powerFlow.isDischarging) ? powerFlow.batteryPower : nil
                    card(icon: powerFlow.isCharging ? "battery.100.bolt" : "battery.100", 
                         title: "电池", 
                         power: batPowerValue,
                         color: powerFlow.isDischarging ? .blue : (powerFlow.isCharging ? .green : .secondary),
                          details: ["\(batteryData?.currentCapacity ?? 0)%", "\(String(format: "%.1fV", batV)) \(String(format: "%.2fA", abs(batA)))"])
                        .offset(x: isExpanded ? 180 : 110)
                        .zIndex(1)
                        .id(3)
                        .onTapGesture { handleTap(3) }
                }
            }
            .offset(x: dragOffset)
            .frame(width: 400, alignment: .center)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard isExpanded else { return }
                        let hasAdapter = powerFlow.adapterPower > 2
                        let proposedOffset = savedOffset + value.translation.width
                        let minBound: CGFloat = hasAdapter ? -70 : 0
                        dragOffset = min(max(proposedOffset, minBound), 70)
                    }
                    .onEnded { value in
                        guard isExpanded else { return }
                        let hasAdapter = powerFlow.adapterPower > 2
                        let minBound: CGFloat = hasAdapter ? -70 : 0
                        let finalOffset = dragOffset
                        let targetOffset: CGFloat
                        if finalOffset > 35 { targetOffset = 70; focusedCard = 1 }
                        else if finalOffset < -35 && hasAdapter { targetOffset = -70; focusedCard = 3 }
                        else { targetOffset = 0; focusedCard = 2 }
                        
                        // Fallback logic incase state changes radically
                        let safeTarget = min(max(targetOffset, minBound), 70)
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dragOffset = safeTarget
                        }
                        savedOffset = safeTarget
                    }
            )
            .padding(.vertical, 8)
            .onChange(of: powerFlow.adapterPower) { newValue in
                // Auto-center bounds recovery if unplugged while focused on card 3
                if newValue <= 2 && savedOffset < 0 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = 0
                        savedOffset = 0
                        focusedCard = 2
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func handleTap(_ id: Int) {
        let hasAdapter = powerFlow.adapterPower > 2
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if isExpanded && focusedCard == id {
                isExpanded = false
                focusedCard = nil
                dragOffset = 0
                savedOffset = 0
            } else {
                isExpanded = true
                focusedCard = id
                
                let targetOffset: CGFloat
                if id == 1 { targetOffset = 70 }
                else if id == 2 { targetOffset = 0 }
                else if id == 3 && hasAdapter { targetOffset = -70 }
                else { targetOffset = 0 }
                
                dragOffset = targetOffset
                savedOffset = targetOffset
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
                    .lineLimit(1)
                    .truncationMode(.tail)
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
        .frame(width: 160, height: 132)
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

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
                    
                    card(icon: "powerplug.fill", 
                         title: adapterName, 
                         power: powerFlow.adapterPower, 
                         color: !powerFlow.isDischarging ? .blue : .secondary.opacity(0.5)) {
                        VStack(alignment: .leading, spacing: 3) {
                            if let adapter = batteryData?.adapter {
                                if let mfg = adapter.manufacturer, !mfg.isEmpty {
                                    let isApple = mfg.localizedCaseInsensitiveContains("apple")
                                    Text(isApple ? "Apple 官方" : mfg)
                                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                        .foregroundColor(isApple ? .blue : .primary.opacity(0.6))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(isApple ? Color.blue.opacity(0.12) : Color.primary.opacity(0.06))
                                        .cornerRadius(4)
                                        .padding(.bottom, 2)
                                }
                                
                                HStack(spacing: 4) {
                                    Text(String(format: "%.2fV", adapterV))
                                    Text("•").foregroundColor(.secondary.opacity(0.5))
                                    Text(String(format: "%.2fA", adapterA))
                                }
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.85))
                                .padding(.bottom, 1)
                                
                                Text("峰值: \(adapter.designWatts)W")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.8))
                                
                                
                                if let profilesText = formattedProfiles(adapter: adapter) {
                                    Text("档位: \(profilesText)")
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                
                                Text("FmCode: \(adapter.familyCode)")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.8))
                            } else {
                                HStack(spacing: 4) {
                                    Text(String(format: "%.2fV", adapterV))
                                    Text("•").foregroundColor(.secondary.opacity(0.5))
                                    Text(String(format: "%.2fA", adapterA))
                                }
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary.opacity(0.85))
                            }
                        }
                    }
                        .offset(x: isExpanded ? -168 : -114)
                        .zIndex(3)
                        .id(1)
                        .onTapGesture { handleTap(1) }
                } else {
                    let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                    let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                    card(icon: "battery.100.bolt",
                         title: "电池输出",
                         power: powerFlow.batteryPower,
                         color: .blue) {
                         VStack(alignment: .leading, spacing: 3) {
                             HStack(spacing: 4) {
                                 Text(String(format: "%.1fV", batV))
                                 Text("•").foregroundColor(.secondary.opacity(0.5))
                                 Text(String(format: "%.2fA", abs(batA)))
                             }
                             .font(.system(size: 10, weight: .bold, design: .monospaced))
                             .foregroundColor(.primary.opacity(0.85))
                             .padding(.bottom, 1)

                             Text("\(batteryData?.currentCapacity ?? 0)% 余量")
                             Text("满充: \(batteryData?.maxCapacity ?? 0) mAh")
                             Text("循环: \(batteryData?.cycleCount ?? 0) 次")
                             Text(String(format: "温度: %.1f°C", batteryData?.temperature ?? 0))
                         }
                         .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                         .foregroundColor(.secondary.opacity(0.8))
                    }
                        .offset(x: isExpanded ? -168 : -114)
                        .zIndex(3)
                        .id(1)
                        .onTapGesture { handleTap(1) }
                }
                
                if isExpanded {
                    Image(systemName: "arrow.right")
                        .foregroundColor(hasAdapter && !powerFlow.isDischarging ? .gray.opacity(0.5) : (!hasAdapter ? .blue.opacity(0.7) : .gray.opacity(0.2)))
                        .font(.system(size: 14, weight: .bold))
                        .offset(x: -84)
                }
                
                // Card 2: System Card
                card(icon: "laptopcomputer", 
                     title: "系统", 
                     power: powerFlow.systemPower, 
                     color: .primary) {
                     VStack(alignment: .leading, spacing: 3) {
                         if let core = powerFlow.coreWatts { Text(String(format: "核心: %.1fW", core)) }
                         if let peri = powerFlow.peripheralWatts { Text(String(format: "外设: %.1fW", peri)) }
                         if let topApp = powerFlow.topAppName, let appW = powerFlow.topAppWatts {
                             Text(String(format: "前台: %.1fW (%@)", appW, String(topApp.prefix(8))))
                         }
                     }
                     .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                     .foregroundColor(.secondary.opacity(0.8))
                }
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
                            .offset(x: 84)
                    }
                    
                    let batV = Double(batteryData?.voltage ?? 0) / 1000.0
                    let batA = Double(batteryData?.amperage ?? 0) / 1000.0
                    let batPowerValue = (powerFlow.isCharging || powerFlow.isDischarging) ? powerFlow.batteryPower : nil
                    card(icon: powerFlow.isCharging ? "battery.100.bolt" : "battery.100", 
                         title: "电池", 
                         power: batPowerValue,
                         color: powerFlow.isDischarging ? .blue : (powerFlow.isCharging ? .green : .secondary)) {
                         VStack(alignment: .leading, spacing: 3) {
                             HStack(spacing: 4) {
                                 Text(String(format: "%.1fV", batV))
                                 Text("•").foregroundColor(.secondary.opacity(0.5))
                                 Text(String(format: "%.2fA", abs(batA)))
                             }
                             .font(.system(size: 10, weight: .bold, design: .monospaced))
                             .foregroundColor(.primary.opacity(0.85))
                             .padding(.bottom, 1)

                             Text("\(batteryData?.currentCapacity ?? 0)% 余量")
                             Text("满充: \(batteryData?.maxCapacity ?? 0) mAh")
                             Text("循环: \(batteryData?.cycleCount ?? 0) 次")
                             Text(String(format: "温度: %.1f°C", batteryData?.temperature ?? 0))
                         }
                         .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                         .foregroundColor(.secondary.opacity(0.8))
                    }
                        .offset(x: isExpanded ? 168 : 114)
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
                        let minBound: CGFloat = hasAdapter ? -54 : 0
                        dragOffset = min(max(proposedOffset, minBound), 54)
                    }
                    .onEnded { value in
                        guard isExpanded else { return }
                        let hasAdapter = powerFlow.adapterPower > 2
                        let minBound: CGFloat = hasAdapter ? -54 : 0
                        let finalOffset = dragOffset
                        let targetOffset: CGFloat
                        if finalOffset > 27 { targetOffset = 54; focusedCard = 1 }
                        else if finalOffset < -27 && hasAdapter { targetOffset = -54; focusedCard = 3 }
                        else { targetOffset = 0; focusedCard = 2 }
                        
                        // Fallback logic incase state changes radically
                        let safeTarget = min(max(targetOffset, minBound), 54)
                        
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
                if id == 1 { targetOffset = 54 }
                else if id == 2 { targetOffset = 0 }
                else if id == 3 && hasAdapter { targetOffset = -54 }
                else { targetOffset = 0 }
                
                dragOffset = targetOffset
                savedOffset = targetOffset
            }
        }
    }

    private func card<Details: View>(icon: String, title: String, power: Double?, color: Color, @ViewBuilder details: () -> Details) -> some View {
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
                Text(NSLocalizedString(title, comment: ""))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 4)
                
                // Details List
                details()
                    .padding(.top, 4)
                
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
        .padding(12)
        .frame(width: 148, height: 160, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    private func formattedProfiles(adapter: AdapterInfo) -> String? {
        guard let active = adapter.activeProfile else { return nil }
        var items = [active]
        if !adapter.profiles.isEmpty {
            for p in adapter.profiles.sorted(by: { $0.maxWatts > $1.maxWatts }) {
                if p.maxVoltage != active.maxVoltage || p.maxCurrent != active.maxCurrent {
                    items.append(p)
                }
            }
        }
        return items.map { pd -> String in
            let vStr = pd.maxVoltage.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", pd.maxVoltage) : String(format: "%.1f", pd.maxVoltage)
            let cStr = pd.maxCurrent.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", pd.maxCurrent) : String(format: "%.2f", pd.maxCurrent)
            return "\(vStr)V/\(cStr)A"
        }.joined(separator: "，")
    }

    private var statusText: String {
        let hasAdapter = powerFlow.adapterPower > 2
        if hasAdapter && powerFlow.isDischarging { return "混合供电" }
        if powerFlow.isCharging { return "电池充电" }
        if powerFlow.isDischarging { return "电池供电" }
        if hasAdapter { return "旁路供电" }
        return "电池闲置"
    }
    
    private var adapterName: String {
        let name = batteryData?.adapter?.name ?? "pd charger"
        if name.lowercased() == "pd charger" || name.lowercased() == "未知设备" {
            let watts = batteryData?.adapter?.designWatts ?? Int(powerFlow.adapterPower)
            if watts > 0 {
                return "通用 \(watts)W PD 充电器"
            }
            return "通用 PD 充电器"
        }
        return name
    }
}

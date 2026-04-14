import SwiftUI

struct SankeyPowerFlowView: View {
    var powerFlow: PowerFlowData
    @AppStorage("powerFlowSankeyAnimated") private var isAnimated = true
    @AppStorage("powerFlowSankeyShowValues") private var showValues = true
    @AppStorage("powerFlowThreeStage") private var isThreeStage = false
    
    var body: some View {
        let appW = powerFlow.topAppWatts ?? 0
        let coreW = powerFlow.coreWatts ?? 0
        let periW = powerFlow.peripheralWatts ?? 0
        let totalSinks = max(appW + coreW + periW, 0.1)
        let elementsCount = (appW > 0.1 ? 1 : 0) + (coreW > 0.1 ? 1 : 0) + (periW > 0.1 ? 1 : 0)
        let sinksHeight = elementsCount > 0 ? ((appW > 0.1 ? max(46.0, 35.0 + 35.0 * (appW/totalSinks)) : 0) + 
                       (coreW > 0.1 ? max(46.0, 35.0 + 35.0 * (coreW/totalSinks)) : 0) + 
                       (periW > 0.1 ? max(46.0, 35.0 + 35.0 * (periW/totalSinks)) : 0) +
                       CGFloat(elementsCount - 1) * 12.0) : 0.0

        VStack(spacing: 12) {
            
            HStack(spacing: -12) {
                
                if powerFlow.topology == .topologyA {
                    // Topology A: Adapter provides all power
                    NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                        .zIndex(1)
                    
                    // Paths VStack
                    VStack(spacing: 12) {
                        // System Path
                        let totalSource = max(powerFlow.adapterPower, 0.1)
                        let sysFlowWatts = powerFlow.systemPower
                        let batChargeWatts = max(powerFlow.batteryPower, 0.0)
                        let effectiveTotalForFractions = max(sysFlowWatts + batChargeWatts, 0.1)
                        let sysFraction = sysFlowWatts / effectiveTotalForFractions
                        let batFraction = batChargeWatts / effectiveTotalForFractions
                        
                        let topHeight = 35.0 + 35.0 * sysFraction
                        
                        HStack(alignment: .top, spacing: -12) {
                            let topThick = max(12.0, CGFloat(sysFraction) * 40.0)
                            let botThick = max(12.0, CGFloat(batFraction) * 40.0)
                            let globalConvergence = topHeight + 6.0
                            
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                mergeMode: (powerFlow.batteryPower > 0.1) ? .topMerge : .none,
                                localConvergenceY: (powerFlow.batteryPower > 0.1) ? globalConvergence : nil,
                                parentHeight: topHeight
                            )
                            .zIndex(0)
                            
                            NodePill(icon: "laptopcomputer", value: showValues ? "\(Int(sysFlowWatts))W" : nil, iconColor: .primary, stretchHeight: true)
                                .zIndex(1)
                                
                            if isThreeStage {
                                ThreeStageSinksView(powerFlow: powerFlow)
                                    .zIndex(0)
                            }
                        }
                        .frame(minHeight: topHeight)
                        
                        // Battery Path
                        if batChargeWatts > 0.1 {
                            let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
                            let actualTopH = isThreeStage ? max(topHeight, sinksHeight) : topHeight
                            let H_total = actualTopH + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                            
                            HStack(alignment: .bottom, spacing: -12) {
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .green,
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)) - (actualTopH + 12.0), botHeight]
                                )
                                .zIndex(0)
                                
                                NodePill(icon: "battery.100.bolt", value: showValues ? "\(Int(batChargeWatts))W" : nil, iconColor: .green, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
                            }
                            .frame(height: botHeight)
                        }
                    }
                    .zIndex(0)
                } else {
                    // Topology B: System is the sink
                    VStack(spacing: 12) {
                        // Is Adapter present?
                        if powerFlow.adapterPower > 0 {
                            // Adapter is MAIN source, Battery is Sub source
                            let totalSource = max(powerFlow.adapterPower + powerFlow.batteryPower, 0.1)
                            let adFraction = powerFlow.adapterPower / totalSource
                            let batFraction = powerFlow.batteryPower / totalSource
                            
                            let topHeight = max(64.0, 35.0 + 35.0 * adFraction)
                            let botHeight = max(64.0, 35.0 + 35.0 * batFraction)
                            
                            let H_total_left = topHeight + (powerFlow.batteryPower > 0.1 ? 12.0 + botHeight : 0)
                            let actualRightH = isThreeStage ? max(70.0, sinksHeight) : 70.0
                            let global_H = max(H_total_left, actualRightH)
                            
                            let leftOffsetY = (global_H - H_total_left) / 2.0
                            let rightOffsetY = (global_H - actualRightH) / 2.0
                            
                            HStack(alignment: .top, spacing: -12) {
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.adapterPower,
                                    fraction: min(adFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false,
                                    parentHeight: topHeight,
                                    explicitRightYRange: [rightOffsetY - leftOffsetY, rightOffsetY + actualRightH * adFraction - leftOffsetY]
                                ).zIndex(0)
                            }.frame(height: topHeight)
                            
                            HStack(alignment: .bottom, spacing: -12) {
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: false, stretchHeight: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .blue,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: true,
                                    parentHeight: botHeight,
                                    explicitRightYRange: [rightOffsetY + actualRightH * adFraction - (leftOffsetY + topHeight + 12.0), rightOffsetY + actualRightH - (leftOffsetY + topHeight + 12.0)]
                                ).zIndex(0)
                            }.frame(height: botHeight)
                        } else {
                            // Battery is MAIN and ONLY source
                            let batFraction = 1.0
                            HStack(spacing: -12) {
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: batFraction,
                                    startColor: .blue,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false
                                ).zIndex(0)
                            }.frame(height: 70)
                        }
                    }
                    .zIndex(0)
                    NodePill(icon: "laptopcomputer", value: showValues ? "\(Int(powerFlow.systemPower))W" : nil, iconColor: .primary, stretchHeight: true)
                        .zIndex(1)
                        
                    if isThreeStage {
                        ThreeStageSinksView(powerFlow: powerFlow)
                            .zIndex(0)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - Subcomponents

struct NodePill: View {
    var icon: String
    var value: String?
    var iconColor: Color
    var isSubNode: Bool = false
    var stretchHeight: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(iconColor)
            
            if let val = value {
                Text(val)
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(.vertical, 8)
        .frame(width: 60)
        .frame(height: stretchHeight ? nil : 70)
        .frame(maxHeight: stretchHeight ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}
enum FlowMergeMode {
    case none
    case topMerge    // Left-side top pipe merging down
    case bottomMerge // Left-side bottom pipe merging up
    case rightTopMerge // Right-side top pipe merging down
    case rightBottomMerge // Right-side bottom pipe merging up
}

struct ThickFlowBlock: View {
    var watts: Double
    var fraction: Double // 0.0 to 1.0 representing percentage of total flow
    var startColor: Color
    var endColor: Color
    var isSubFlow: Bool = false
    var leftConnectHeight: CGFloat? = nil
    var rightConnectHeight: CGFloat? = nil
    var mergeMode: FlowMergeMode = .none
    var localConvergenceY: CGFloat? = nil
    var parentHeight: CGFloat? = nil
    var explicitLeftYRange: [CGFloat]? = nil
    var explicitRightYRange: [CGFloat]? = nil
    
    @AppStorage("powerFlowSankeyAnimated") private var isAnimated = true
    @AppStorage("powerFlowSankeyShowValues") private var showValues = true
    @AppStorage("powerFlowSankeyStyle") private var sankeyStyle = "watchband"
    
    @State private var phase = 0.0
    
    var body: some View {
        let baseHeight: CGFloat = isSubFlow ? 35 : 70
        let actualParentH = parentHeight ?? baseHeight
        
        // Proportional waist for watchband style:
        let proportionalThickness = max(12.0, CGFloat(fraction) * 40.0)
        
        let isStandard = sankeyStyle == "standard"
        // Standard is uniformly thick (eats actualParentH everywhere)
        // Watchband shrinks in the middle (waist) but flares to actualParentH at endpoints
        let thickness = isStandard ? actualParentH : proportionalThickness
        
        let leftH = leftConnectHeight ?? actualParentH
        let rightH = rightConnectHeight ?? actualParentH
        
        ZStack {
            // White base behind everything
            WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle, explicitLeftYRange: explicitLeftYRange, explicitRightYRange: explicitRightYRange)
                .fill(Color.white)
            
            // The Block
            WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle, explicitLeftYRange: explicitLeftYRange, explicitRightYRange: explicitRightYRange)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            startColor.opacity(0.9),
                            endColor.opacity(0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    // Flow animation overlay
                    WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle, explicitLeftYRange: explicitLeftYRange, explicitRightYRange: explicitRightYRange)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color.white.opacity(0.4), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: UnitPoint(x: phase - 0.5, y: 0),
                                endPoint: UnitPoint(x: phase + 0.5, y: 0)
                            )
                        )
                        .blendMode(.overlay)
                        .clipShape(WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH, mergeMode: mergeMode, localConvergenceY: localConvergenceY, sankeyStyle: sankeyStyle, explicitLeftYRange: explicitLeftYRange, explicitRightYRange: explicitRightYRange))
                        .animation(isAnimated ? .linear(duration: 1.5).repeatForever(autoreverses: false) : .default, value: phase)
                        .opacity(isAnimated ? 1.0 : 0.0)
                )
            
            // Text inside the block
            if showValues {
                let textValue = (watts == -1.0) ? "-- W" : String(format: "%.2f W", watts)
                Text(textValue)
                    .font(.system(size: isSubFlow ? 10 : 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSubFlow ? .secondary : .primary)
                    // White shadow to ensure readability on variable colors
                    .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
                    .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            phase = 1.0
        }
    }
}

struct WatchBandShape: Shape {
    var thickness: CGFloat
    var leftHeight: CGFloat
    var rightHeight: CGFloat
    var mergeMode: FlowMergeMode = .none
    var localConvergenceY: CGFloat? = nil
    var sankeyStyle: String = "watchband"
    var explicitLeftYRange: [CGFloat]? = nil
    var explicitRightYRange: [CGFloat]? = nil
    
    var animatableData: CGFloat {
        get { thickness }
        set { thickness = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let centerY = h / 2.0
        
        // By allowing the constraint clamping boundary to dip below safeThick,
        // it enables dynamic Funnel-tapering for very thick pipes squeezing into narrow terminal node slots.
        let safeThick = min(thickness, h)
        let clampedLeft = min(leftHeight, h)
        let clampedRight = min(rightHeight, h)
        
        let halfThick = safeThick / 2.0
        let halfLeft = clampedLeft / 2.0
        let halfRight = clampedRight / 2.0
        
        var realLeftCurveW: CGFloat = w * 0.75 // Default sweep side
        var realRightCurveW: CGFloat = min(w - realLeftCurveW, 32.0)
        
        if mergeMode == .rightTopMerge || mergeMode == .rightBottomMerge {
            // Swap sweep lengths so the long graceful sweep happens on the right side
            realRightCurveW = w * 0.75
            realLeftCurveW = min(w - realRightCurveW, 32.0)
        }
        
        // Dynamic Anchor Calculations for contiguous Y-gap bridging
        let defaultTopY = centerY - halfLeft
        let defaultBotY = centerY + halfLeft
        let defaultRightTopY = centerY - halfRight
        let defaultRightBotY = centerY + halfRight
        
        var leftTopY = defaultTopY
        var leftBotY = defaultBotY
        var rightTopY = defaultRightTopY
        var rightBotY = defaultRightBotY
        
        let mergeSpread = sankeyStyle == "standard" ? safeThick : (safeThick * 1.5 + 12.0)
        
        // Apply Left merges
        if mergeMode == .topMerge, let convergence = localConvergenceY {
            leftBotY = convergence
            leftTopY = convergence - mergeSpread // Expands dynamically to form a visually substantial Y-fork
        } else if mergeMode == .bottomMerge, let convergence = localConvergenceY {
            leftTopY = convergence
            leftBotY = convergence + mergeSpread
        }
        
        // Apply Right merges
        if mergeMode == .rightTopMerge, let convergence = localConvergenceY {
            rightBotY = convergence
            rightTopY = convergence - mergeSpread
        } else if mergeMode == .rightBottomMerge, let convergence = localConvergenceY {
            rightTopY = convergence
            rightBotY = convergence + mergeSpread
        }
        
        
        path.move(to: CGPoint(x: 0, y: leftTopY))
        
        if sankeyStyle == "standard" {
            // Standard continuous Sankey S-curve
            path.addCurve(to: CGPoint(x: w, y: rightTopY),
                          control1: CGPoint(x: w * 0.5, y: leftTopY),
                          control2: CGPoint(x: w * 0.5, y: rightTopY))
            
            path.addLine(to: CGPoint(x: w, y: rightBotY))
            
            path.addCurve(to: CGPoint(x: 0, y: leftBotY),
                          control1: CGPoint(x: w * 0.5, y: rightBotY),
                          control2: CGPoint(x: w * 0.5, y: leftBotY))
            
            path.closeSubpath()
            return path
        }
        
        // Left sweep/flare (Top Edge)
        path.addCurve(to: CGPoint(x: realLeftCurveW, y: centerY - halfThick),
                      control1: CGPoint(x: realLeftCurveW * 0.5, y: leftTopY),
                      control2: CGPoint(x: realLeftCurveW * 0.5, y: centerY - halfThick))
        
        // Straight segment
        path.addLine(to: CGPoint(x: w - realRightCurveW, y: centerY - halfThick))
        
        // Right sweep/flare (Top Edge)
        path.addCurve(to: CGPoint(x: w, y: rightTopY),
                      control1: CGPoint(x: w - realRightCurveW * 0.5, y: centerY - halfThick),
                      control2: CGPoint(x: w - realRightCurveW * 0.5, y: rightTopY))
        
        // Right edge
        path.addLine(to: CGPoint(x: w, y: rightBotY))
        
        // Right sweep/flare (Bottom Edge)
        path.addCurve(to: CGPoint(x: w - realRightCurveW, y: centerY + halfThick),
                      control1: CGPoint(x: w - realRightCurveW * 0.5, y: rightBotY),
                      control2: CGPoint(x: w - realRightCurveW * 0.5, y: centerY + halfThick))
        
        // Straight segment back
        path.addLine(to: CGPoint(x: realLeftCurveW, y: centerY + halfThick))
        
        // Left sweep/flare (Bottom Edge)
        path.addCurve(to: CGPoint(x: 0, y: leftBotY),
                      control1: CGPoint(x: realLeftCurveW * 0.5, y: centerY + halfThick),
                      control2: CGPoint(x: realLeftCurveW * 0.5, y: leftBotY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Three Stage Sinks View

struct ThreeStageSinksView: View {
    var powerFlow: PowerFlowData
    @AppStorage("powerFlowSankeyShowValues") private var showValues = true
    
    var body: some View {
        let appW = powerFlow.topAppWatts ?? 0.0
        let coreW = powerFlow.coreWatts ?? 0.0
        let periW = powerFlow.peripheralWatts ?? 0.0
        
        let total = max(appW + coreW + periW, 0.1)
        
        let appF = appW / total
        let coreF = coreW / total
        let periF = periW / total
        
        let elementsCount = (appW > 0.1 ? 1 : 0) + (coreW > 0.1 ? 1 : 0) + (periW > 0.1 ? 1 : 0)
        
        VStack(spacing: 12) {
            // 1. Top App
            if appW > 0.1 {
                let h = 35.0 + 35.0 * appF
                HStack(alignment: .center, spacing: -12) {
                    ThickFlowBlock(
                        watts: appW, 
                        fraction: appF, 
                        startColor: .primary.opacity(0.8), 
                        endColor: .orange, 
                        mergeMode: elementsCount > 1 ? .topMerge : .none, 
                        localConvergenceY: elementsCount > 1 ? h + 12.0 : nil,
                        parentHeight: h
                    )
                    .zIndex(0)
                    
                    NodePill(icon: "app.badge.fill", value: showValues ? (powerFlow.topAppName ?? "App") : nil, iconColor: .orange, stretchHeight: true)
                        .zIndex(1)
                }
                .frame(height: h)
            }
            
            // 2. Core
            if coreW > 0.1 {
                let h = 35.0 + 35.0 * coreF
                HStack(alignment: .center, spacing: -12) {
                    ThickFlowBlock(
                        watts: coreW, 
                        fraction: coreF, 
                        startColor: .primary.opacity(0.8), 
                        endColor: .cyan, 
                        mergeMode: .none,
                        parentHeight: h
                    )
                    .zIndex(0)
                    
                    NodePill(icon: "cpu", value: showValues ? "\(String(format: "%.1f", coreW))W" : nil, iconColor: .cyan, stretchHeight: true)
                        .zIndex(1)
                }
                .frame(height: h)
            }
            
            // 3. Peripherals
            if periW > 0.1 {
                let h = 35.0 + 35.0 * periF
                HStack(alignment: .center, spacing: -12) {
                    ThickFlowBlock(
                        watts: periW, 
                        fraction: periF, 
                        startColor: .primary.opacity(0.8), 
                        endColor: .gray, 
                        mergeMode: elementsCount > 1 ? .bottomMerge : .none, 
                        localConvergenceY: elementsCount > 1 ? -12.0 : nil,
                        parentHeight: h
                    )
                    .zIndex(0)
                    
                    NodePill(icon: "cable.connector", value: showValues ? "\(String(format: "%.1f", periW))W" : nil, iconColor: .gray, stretchHeight: true)
                        .zIndex(1)
                }
                .frame(height: h)
            }
        }
    }
}

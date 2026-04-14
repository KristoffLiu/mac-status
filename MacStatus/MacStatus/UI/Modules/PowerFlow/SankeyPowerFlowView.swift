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
                    let totalSource = max(powerFlow.adapterPower, 0.1)
                    let sysFlowWatts = powerFlow.systemPower
                    let batChargeWatts = max(powerFlow.batteryPower, 0.0)
                    let effectiveTotalForFractions = max(sysFlowWatts + batChargeWatts, 0.1)
                    let sysFraction = sysFlowWatts / effectiveTotalForFractions
                    let batFraction = batChargeWatts / effectiveTotalForFractions
                    
                    let dynamicBaseHeight = 64.0 + CGFloat(pow(min(totalSource, 140.0) / 140.0, 0.6)) * 56.0
                    
                    let topHeightRaw = dynamicBaseHeight * sysFraction
                    let topHeight = max(64.0, topHeightRaw)
                    
                    let botHeightRaw = dynamicBaseHeight * batFraction
                    let predictedBotHeight = max(64.0, botHeightRaw)
                    let actualTopH = isThreeStage ? max(topHeight, sinksHeight) : topHeight
                    let H_total = actualTopH + (batChargeWatts > 0.1 ? 12.0 + predictedBotHeight : 0)
                    
                    // Root Container
                    HStack(alignment: .top, spacing: -12) {
                        
                        // Col 1: Adapter
                        NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                            .frame(height: H_total)
                            .zIndex(2)
                        
                        // Col 2: Pipes
                        VStack(spacing: 12) {
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false,
                                parentHeight: actualTopH,
                                explicitLeftYRange: [0, H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts))]
                            )
                            .frame(height: actualTopH)
                            .zIndex(0)
                            
                            if batChargeWatts > 0.1 {
                                ThickFlowBlock(
                                    watts: batChargeWatts,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .green,
                                    isSubFlow: true,
                                    parentHeight: predictedBotHeight,
                                    explicitLeftYRange: [H_total * (sysFlowWatts / (sysFlowWatts + batChargeWatts)) - (actualTopH + 12.0), predictedBotHeight]
                                )
                                .frame(height: predictedBotHeight)
                                .zIndex(0)
                            }
                        }
                        .zIndex(0)
                        
                        // Col 3: System & Battery Nodes
                        VStack(spacing: 12) {
                            NodePill(icon: "laptopcomputer", value: showValues ? "\(Int(sysFlowWatts))W" : nil, iconColor: .primary, stretchHeight: true)
                                .frame(height: actualTopH)
                                .zIndex(1)
                                
                            if batChargeWatts > 0.1 {
                                NodePill(icon: "battery.100.bolt", value: showValues ? "\(Int(batChargeWatts))W" : nil, iconColor: .green, stretchHeight: true)
                                    .frame(height: predictedBotHeight)
                                    .zIndex(1)
                            }
                        }
                        .zIndex(1)
                        
                        // Col 4 & 5: Three Stage Sinks
                        if isThreeStage {
                            ThreeStageSinksView(powerFlow: powerFlow)
                                .frame(height: actualTopH)
                                .zIndex(0)
                        }
                    }
                } else {
                    // Topology B: System is the sink
                    let totalSource = max(powerFlow.adapterPower + powerFlow.batteryPower, 0.1)
                    let adFraction = powerFlow.adapterPower / totalSource
                    let batFraction = powerFlow.batteryPower / totalSource
                    
                    let dynamicBaseHeight = 64.0 + CGFloat(pow(min(totalSource, 140.0) / 140.0, 0.6)) * 56.0
                    
                    let topHeightRaw = dynamicBaseHeight * adFraction
                    let botHeightRaw = dynamicBaseHeight * batFraction
                    
                    let topHeight = powerFlow.adapterPower > 0 ? max(64.0, topHeightRaw) : 0.0
                    let botHeight = powerFlow.batteryPower > 0 ? max(64.0, botHeightRaw) : 0.0
                    
                    let H_total_left = topHeight + botHeight + (powerFlow.adapterPower > 0 && powerFlow.batteryPower > 0 ? 12.0 : 0.0)
                    let actualRightH = isThreeStage ? max(70.0, sinksHeight) : 70.0
                    let global_H = max(H_total_left, actualRightH)
                    
                    let leftOffsetY = (global_H - H_total_left) / 2.0
                    let rightOffsetY = (global_H - actualRightH) / 2.0
                    
                    // Root Container
                    HStack(alignment: .center, spacing: -12) {
                        
                        if powerFlow.adapterPower > 0 || powerFlow.batteryPower > 0 {
                            // Col 1: Sources
                            VStack(spacing: 12) {
                                if powerFlow.adapterPower > 0 {
                                    NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8), stretchHeight: true)
                                        .frame(height: topHeight)
                                        .zIndex(2)
                                }
                                if powerFlow.batteryPower > 0 {
                                    NodePill(icon: "battery.100", value: nil, iconColor: .blue, stretchHeight: true)
                                        .frame(height: botHeight)
                                        .zIndex(2)
                                }
                            }
                            .zIndex(2)
                            
                            // Col 2: Pipes
                            let offsetGap = (powerFlow.adapterPower > 0 && powerFlow.batteryPower > 0) ? 12.0 : 0.0
                            VStack(spacing: 12) {
                                if powerFlow.adapterPower > 0 {
                                    ThickFlowBlock(
                                        watts: powerFlow.adapterPower,
                                        fraction: min(adFraction, 1.0),
                                        startColor: .yellow.opacity(0.8),
                                        endColor: .gray.opacity(0.2),
                                        isSubFlow: false,
                                        parentHeight: topHeight,
                                        explicitRightYRange: [rightOffsetY - leftOffsetY, rightOffsetY + actualRightH * adFraction - leftOffsetY]
                                    )
                                    .frame(height: topHeight)
                                    .zIndex(0)
                                }
                                
                                if powerFlow.batteryPower > 0 {
                                    ThickFlowBlock(
                                        watts: powerFlow.batteryPower,
                                        fraction: min(batFraction, 1.0),
                                        startColor: .blue,
                                        endColor: .gray.opacity(0.2),
                                        isSubFlow: powerFlow.adapterPower > 0,
                                        parentHeight: botHeight,
                                        explicitRightYRange: [rightOffsetY + actualRightH * adFraction - (leftOffsetY + topHeight + offsetGap), rightOffsetY + actualRightH - (leftOffsetY + topHeight + offsetGap)]
                                    )
                                    .frame(height: botHeight)
                                    .zIndex(0)
                                }
                            }
                            .zIndex(0)
                        } else {
                            // Fallback minimal column layout
                            VStack(spacing: 12) {
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .gray, stretchHeight: true)
                                    .frame(height: 70)
                                    .zIndex(2)
                            }
                            VStack(spacing: 12) {
                                ThickFlowBlock(
                                    watts: 0,
                                    fraction: 1.0,
                                    startColor: .gray,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false,
                                    parentHeight: 70
                                )
                                .frame(height: 70)
                                .zIndex(0)
                            }
                        }
                        
                        // Col 3: System Node
                        NodePill(icon: "laptopcomputer", value: showValues ? "\(Int(powerFlow.systemPower))W" : nil, iconColor: .primary, stretchHeight: true)
                            .frame(height: actualRightH)
                            .zIndex(1)
                            
                        // Col 4 & 5: Three Stage Sinks
                        if isThreeStage {
                            ThreeStageSinksView(powerFlow: powerFlow)
                                .frame(height: actualRightH)
                                .zIndex(0)
                        }
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
    var width: CGFloat = 60.0
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(iconColor)
            
            if let val = value {
                Text(val)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 8)
        .frame(width: width)
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
    
    private var textYOffset: CGFloat {
        let baseHeight: CGFloat = isSubFlow ? 35.0 : 70.0
        let actH: CGFloat = parentHeight ?? baseHeight
        
        var leftMid = actH / 2.0
        if let el = explicitLeftYRange, el.count == 2 {
            leftMid = (el[0] + el[1]) / 2.0
        }
        
        var rightMid = actH / 2.0
        if let er = explicitRightYRange, er.count == 2 {
            rightMid = (er[0] + er[1]) / 2.0
        }
        
        let pathCenterY = (leftMid + rightMid) / 2.0
        return pathCenterY - (actH / 2.0)
    }
    
    var body: some View {
        let baseHeight: CGFloat = isSubFlow ? 35 : 70
        let actualParentH = parentHeight ?? baseHeight
        
        // Proportional waist for watchband style:
        let proportionalThickness = max(24.0, CGFloat(fraction) * 52.0)
        
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
                let dynamicSize: CGFloat = proportionalThickness > 35 ? 14 : (proportionalThickness > 25 ? 12 : 10)
                let dynamicColor: Color = proportionalThickness > 25 ? .primary : .secondary
                
                Text(textValue)
                    .font(.system(size: dynamicSize, weight: .bold, design: .rounded))
                    .foregroundColor(dynamicColor)
                    // White shadow to ensure readability on variable colors
                    .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
                    .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
                    .offset(y: textYOffset)
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
        
        // --- Apple Watch Band Organic Geometry ---
        // Expand the curvature zone to make the transition incredibly swoopy and soft
        let curveW = w * 0.45
        
        var realLeftCurveW: CGFloat = curveW
        var realRightCurveW: CGFloat = curveW
        
        // If merging asymmetrically, skew the curve lengths slightly
        if mergeMode == .rightTopMerge || mergeMode == .rightBottomMerge {
            realRightCurveW = w * 0.6
            realLeftCurveW = w * 0.3
        } else if mergeMode == .topMerge || mergeMode == .bottomMerge {
            realLeftCurveW = w * 0.6
            realRightCurveW = w * 0.3
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
        if let explicitLeft = explicitLeftYRange, explicitLeft.count == 2 {
            leftTopY = explicitLeft[0]
            leftBotY = explicitLeft[1]
        } else if mergeMode == .topMerge, let convergence = localConvergenceY {
            leftBotY = convergence
            leftTopY = convergence - mergeSpread // Expands dynamically to form a visually substantial Y-fork
        } else if mergeMode == .bottomMerge, let convergence = localConvergenceY {
            leftTopY = convergence
            leftBotY = convergence + mergeSpread
        }
        
        // Apply Right merges
        if let explicitRight = explicitRightYRange, explicitRight.count == 2 {
            rightTopY = explicitRight[0]
            rightBotY = explicitRight[1]
        } else if mergeMode == .rightTopMerge, let convergence = localConvergenceY {
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
                      control1: CGPoint(x: realLeftCurveW * 0.6, y: leftTopY),
                      control2: CGPoint(x: realLeftCurveW * 0.4, y: centerY - halfThick))
        
        // Straight segment
        path.addLine(to: CGPoint(x: w - realRightCurveW, y: centerY - halfThick))
        
        // Right sweep/flare (Top Edge)
        path.addCurve(to: CGPoint(x: w, y: rightTopY),
                      control1: CGPoint(x: w - realRightCurveW * 0.6, y: centerY - halfThick),
                      control2: CGPoint(x: w - realRightCurveW * 0.4, y: rightTopY))
        
        // Right edge
        path.addLine(to: CGPoint(x: w, y: rightBotY))
        
        // Right sweep/flare (Bottom Edge)
        path.addCurve(to: CGPoint(x: w - realRightCurveW, y: centerY + halfThick),
                      control1: CGPoint(x: w - realRightCurveW * 0.4, y: rightBotY),
                      control2: CGPoint(x: w - realRightCurveW * 0.6, y: centerY + halfThick))
        
        // Straight segment back
        path.addLine(to: CGPoint(x: realLeftCurveW, y: centerY + halfThick))
        
        // Left sweep/flare (Bottom Edge)
        path.addCurve(to: CGPoint(x: 0, y: leftBotY),
                      control1: CGPoint(x: realLeftCurveW * 0.4, y: centerY + halfThick),
                      control2: CGPoint(x: realLeftCurveW * 0.6, y: leftBotY))
        
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
                let h = max(46.0, 100.0 * appF)
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
                    
                    NodePill(icon: "app.badge.fill", value: showValues ? (powerFlow.topAppName ?? "App") : nil, iconColor: .orange, stretchHeight: true, width: 80.0)
                        .zIndex(1)
                }
                .frame(height: h)
            }
            
            // 2. Core
            if coreW > 0.1 {
                let h = max(46.0, 100.0 * coreF)
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
                    
                    NodePill(icon: "cpu", value: showValues ? "\(String(format: "%.1f", coreW))W" : nil, iconColor: .cyan, stretchHeight: true, width: 80.0)
                        .zIndex(1)
                }
                .frame(height: h)
            }
            
            // 3. Peripherals
            if periW > 0.1 {
                let h = max(46.0, 100.0 * periF)
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
                    
                    NodePill(icon: "cable.connector", value: showValues ? "\(String(format: "%.1f", periW))W" : nil, iconColor: .gray, stretchHeight: true, width: 80.0)
                        .zIndex(1)
                }
                .frame(height: h)
            }
        }
    }
}

import SwiftUI

struct SankeyPowerFlowView: View {
    var powerFlow: PowerFlowData
    
    var body: some View {
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
                        let sysFraction = sysFlowWatts / totalSource
                        
                        HStack(spacing: -12) {
                            ThickFlowBlock(
                                watts: sysFlowWatts,
                                fraction: min(sysFraction, 1.0),
                                startColor: .yellow.opacity(0.8),
                                endColor: .gray.opacity(0.2),
                                isSubFlow: false
                            )
                            .zIndex(0)
                            
                            NodePill(icon: "laptopcomputer", value: "\(Int(sysFlowWatts))W", iconColor: .primary)
                                .zIndex(1)
                        }
                        .frame(height: 70)
                        
                        // Battery Path
                        if powerFlow.batteryPower > 0.1 {
                            let batFraction = powerFlow.batteryPower / totalSource
                            HStack(spacing: -12) {
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .green,
                                    isSubFlow: true
                                )
                                .zIndex(0)
                                
                                NodePill(icon: "battery.100.bolt", value: "\(Int(powerFlow.batteryPower))W", iconColor: .green, isSubNode: true)
                                    .frame(width: 60, alignment: .center)
                                    .zIndex(1)
                            }
                            .frame(height: 35)
                        }
                    }
                    .zIndex(0)
                } else {
                    // Topology B: System is the sink
                    VStack(spacing: 12) {
                        // Is Adapter present?
                        if powerFlow.adapterPower > 0 {
                            // Adapter is MAIN source, Battery is Sub source
                            let totalSource = powerFlow.adapterPower + powerFlow.batteryPower
                            let adFraction = powerFlow.adapterPower / max(totalSource, 0.1)
                            HStack(spacing: -12) {
                                NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8))
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.adapterPower,
                                    fraction: min(adFraction, 1.0),
                                    startColor: .yellow.opacity(0.8),
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: false
                                ).zIndex(0)
                            }.frame(height: 70)
                            
                            let batFraction = powerFlow.batteryPower / max(totalSource, 0.1)
                            HStack(spacing: -12) {
                                NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: true)
                                    .zIndex(1)
                                ThickFlowBlock(
                                    watts: powerFlow.batteryPower,
                                    fraction: min(batFraction, 1.0),
                                    startColor: .blue,
                                    endColor: .gray.opacity(0.2),
                                    isSubFlow: true
                                ).zIndex(0)
                            }.frame(height: 35)
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
                    
                    NodePill(icon: "laptopcomputer", value: "\(Int(powerFlow.systemPower))W", iconColor: .primary, stretchHeight: true)
                        .zIndex(1)
                }
            }
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
                .font(.system(size: isSubNode ? 14 : 20, weight: .regular))
                .foregroundColor(iconColor)
            
            if let val = value {
                Text(val)
                    .font(.system(size: isSubNode ? 10 : 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: isSubNode ? 50 : 60)
        .frame(height: stretchHeight ? nil : (isSubNode ? 35 : 70))
        .frame(maxHeight: stretchHeight ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
}

struct ThickFlowBlock: View {
    var watts: Double
    var fraction: Double // 0.0 to 1.0 representing percentage of total flow
    var startColor: Color
    var endColor: Color
    var isSubFlow: Bool = false
    var leftConnectHeight: CGFloat? = nil
    var rightConnectHeight: CGFloat? = nil
    
    @State private var phase = 0.0
    
    // True Sankey logic: thickness is proportional to its fraction of total power
    private var thickness: CGFloat {
        let maxThickness: CGFloat = isSubFlow ? 24.0 : 40.0
        return max(12.0, CGFloat(fraction) * maxThickness)
    }
    
    var body: some View {
        let baseHeight: CGFloat = isSubFlow ? 35 : 70
        // Left connection overlaps the flat "back" of the left node, so it safely supports a larger flare.
        let leftH = leftConnectHeight ?? min(thickness + 16.0, max(thickness, baseHeight - 8.0))
        // Right connection hits the leading rounded corner of the right node, so it MUST be strictly clamped to the flat plane (height - 24).
        let rightH = rightConnectHeight ?? min(thickness + 16.0, max(thickness, baseHeight - 24.0))
        
        ZStack {
            // White base behind everything
            WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH)
                .fill(Color.white)
            
            // The Block
            WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH)
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
                    WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH)
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
                        .clipShape(WatchBandShape(thickness: thickness, leftHeight: leftH, rightHeight: rightH))
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                )
            
            // Text inside the block
            let textValue = (watts == -1.0) ? "-- W" : String(format: "%.2f W", watts)
            Text(textValue)
                .font(.system(size: isSubFlow ? 10 : 14, weight: .bold, design: .rounded))
                .foregroundColor(isSubFlow ? .secondary : .primary)
                // White shadow to ensure readability on variable colors
                .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
                .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 2, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: baseHeight)
        .onAppear {
            phase = 1.0
        }
    }
}

struct WatchBandShape: Shape {
    var thickness: CGFloat
    var leftHeight: CGFloat
    var rightHeight: CGFloat
    
    var animatableData: CGFloat {
        get { thickness }
        set { thickness = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let centerY = h / 2.0
        
        // Ensure values are sane
        let safeThick = min(thickness, h)
        let clampedLeft = min(max(safeThick, leftHeight), h)
        let clampedRight = min(max(safeThick, rightHeight), h)
        
        let halfThick = safeThick / 2.0
        let halfLeft = clampedLeft / 2.0
        let halfRight = clampedRight / 2.0
        
        let curveW: CGFloat = 48.0
        
        path.move(to: CGPoint(x: 0, y: centerY - halfLeft))
        
        path.addCurve(to: CGPoint(x: curveW, y: centerY - halfThick),
                      control1: CGPoint(x: curveW * 0.5, y: centerY - halfLeft),
                      control2: CGPoint(x: curveW * 0.5, y: centerY - halfThick))
        
        path.addLine(to: CGPoint(x: max(curveW, w - curveW), y: centerY - halfThick))
        
        path.addCurve(to: CGPoint(x: w, y: centerY - halfRight),
                      control1: CGPoint(x: w - curveW * 0.5, y: centerY - halfThick),
                      control2: CGPoint(x: w - curveW * 0.5, y: centerY - halfRight))
        
        path.addLine(to: CGPoint(x: w, y: centerY + halfRight))
        
        path.addCurve(to: CGPoint(x: max(curveW, w - curveW), y: centerY + halfThick),
                      control1: CGPoint(x: w - curveW * 0.5, y: centerY + halfRight),
                      control2: CGPoint(x: w - curveW * 0.5, y: centerY + halfThick))
        
        path.addLine(to: CGPoint(x: curveW, y: centerY + halfThick))
        
        path.addCurve(to: CGPoint(x: 0, y: centerY + halfLeft),
                      control1: CGPoint(x: curveW * 0.5, y: centerY + halfThick),
                      control2: CGPoint(x: curveW * 0.5, y: centerY + halfLeft))
        
        path.closeSubpath()
        return path
    }
}

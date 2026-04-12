import SwiftUI

struct SankeyPowerFlowView: View {
    var powerFlow: PowerFlowData
    
    var body: some View {
        VStack(spacing: 12) {
            
            // MAIN SYSTEM ROW: Adapter -> System (or Battery -> System if unplugged)
            HStack(spacing: 8) {
                // Main Source: Adapter if plugged in, else Battery
                if powerFlow.adapterPower > 0 || powerFlow.topology == .topologyA {
                    NodePill(icon: "powerplug.fill", value: nil, iconColor: .yellow.opacity(0.8))
                } else {
                    NodePill(icon: "battery.100", value: nil, iconColor: .blue)
                }
                
                // Base absolute reference mapping for proportional flow
                let totalSource = max(powerFlow.adapterPower, powerFlow.batteryPower, 0.1)
                
                // Flow Block for System
                let sysFlowWatts = powerFlow.systemPower > 0 ? powerFlow.systemPower : (powerFlow.adapterPower > 0 ? powerFlow.adapterPower : powerFlow.batteryPower)
                let sysFraction = sysFlowWatts / totalSource
                
                ThickFlowBlock(
                    watts: sysFlowWatts,
                    fraction: min(sysFraction, 1.0),
                    startColor: (powerFlow.adapterPower > 0 || powerFlow.topology == .topologyA) ? .yellow.opacity(0.8) : .blue,
                    endColor: .gray.opacity(0.2)
                )
                
                // Main Sink: System
                NodePill(icon: "laptopcomputer", value: "\(Int(sysFlowWatts))W", iconColor: .primary)
            }
            .frame(height: 70)
            
            // SUB ROW: Battery Charging/Discharging (only if Battery is active and NOT the main source)
            if powerFlow.adapterPower > 0 && powerFlow.batteryPower > 0.1 {
                let totalSource = max(powerFlow.adapterPower, 0.1)
                let batFraction = powerFlow.batteryPower / totalSource
                
                HStack(spacing: 8) {
                    
                    // Invisible spacer node on left to align with above (Adapter)
                    Color.clear.frame(width: 60)
                    
                    // Secondary Flow to/from Battery
                    if powerFlow.topology == .topologyA {
                        // Adapter -> Battery (Charging)
                        ThickFlowBlock(
                            watts: powerFlow.batteryPower,
                            fraction: min(batFraction, 1.0),
                            startColor: .yellow.opacity(0.8),
                            endColor: .green,
                            isSubFlow: true
                        )
                        NodePill(icon: "battery.100.bolt", value: "\(Int(powerFlow.batteryPower))W", iconColor: .green, isSubNode: true)
                    } else {
                        // Battery -> System (Discharging alongside Adapter)
                        // This rarely happens in M-series (usually Adapter bypasses or both drain), but just in case
                        NodePill(icon: "battery.100", value: nil, iconColor: .blue, isSubNode: true)
                        ThickFlowBlock(
                            watts: powerFlow.batteryPower,
                            fraction: min(batFraction, 1.0),
                            startColor: .blue,
                            endColor: .gray.opacity(0.2),
                            isSubFlow: true
                        )
                    }
                }
                .frame(height: 40)
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
        .frame(width: isSubNode ? 50 : 60, height: isSubNode ? 35 : 70)
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
    
    @State private var phase = 0.0
    
    // True Sankey logic: thickness is proportional to its fraction of total power
    private var thickness: CGFloat {
        let maxThickness: CGFloat = isSubFlow ? 36.0 : 56.0
        return max(12.0, CGFloat(fraction) * maxThickness)
    }
    
    var body: some View {
        ZStack {
            // The Block
            RoundedRectangle(cornerRadius: 8)
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
                .frame(height: thickness)
                .overlay(
                    // Flow animation overlay
                    RoundedRectangle(cornerRadius: 8)
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        .frame(maxWidth: .infinity)
        .onAppear {
            phase = 1.0
        }
    }
}

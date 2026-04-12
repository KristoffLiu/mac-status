import SwiftUI

struct SankeyPowerFlowView: View {
    var powerFlow: PowerFlowData
    
    var body: some View {
        HStack(spacing: 8) {
            // Left Column (Sources)
            VStack(spacing: 0) {
                sourceNode(name: "Adapter", icon: "powerplug.fill", watts: powerFlow.adapterPower, color: UIConstants.Colors.adapterAmber)
                Spacer()
                if powerFlow.topology == .topologyB {
                    sourceNode(name: "Battery", icon: "battery.100", watts: powerFlow.batteryPower, color: UIConstants.Colors.dischargingBlue)
                } else {
                    Color.clear.frame(height: 50)
                }
            }
            .frame(width: 80, height: 100)
            

            // Middle Column (Sankey Paths)
            GeometryReader { geometry in
                let w = geometry.size.width
                let h = geometry.size.height
                let topY = h * 0.25
                let bottomY = h * 0.75
                
                ZStack {
                    if powerFlow.topology == .topologyA {
                        // Adapter -> System
                        if powerFlow.systemPower != 0 {
                            // If systemPower is unknown (-1.0), base visual thickness on adapter power
                            let displayWidth = powerFlow.systemPower > 0 ? powerFlow.systemPower : powerFlow.adapterPower
                            ThickFlowPath(
                                startPoint: CGPoint(x: 0, y: topY),
                                endPoint: CGPoint(x: w, y: topY),
                                startColor: UIConstants.Colors.adapterAmber,
                                endColor: UIConstants.Colors.adapterAmber,
                                width: lineWidth(for: displayWidth)
                            )
                        }
                        
                        // Adapter -> Battery (Charging)
                        if powerFlow.batteryPower > 0.1 {
                            ThickFlowPath(
                                startPoint: CGPoint(x: 0, y: topY),
                                endPoint: CGPoint(x: w, y: bottomY),
                                startColor: UIConstants.Colors.adapterAmber,
                                endColor: UIConstants.Colors.chargingGreen,
                                width: lineWidth(for: powerFlow.batteryPower)
                            )
                        }
                    } else {
                        // Adapter -> System (if any adapter power)
                        if powerFlow.adapterPower > 0.1 {
                            ThickFlowPath(
                                startPoint: CGPoint(x: 0, y: topY),
                                endPoint: CGPoint(x: w, y: topY),
                                startColor: UIConstants.Colors.adapterAmber,
                                endColor: UIConstants.Colors.adapterAmber,
                                width: lineWidth(for: powerFlow.adapterPower)
                            )
                        }
                        
                        // Battery -> System (Discharging)
                        if powerFlow.batteryPower > 0.1 {
                            ThickFlowPath(
                                startPoint: CGPoint(x: 0, y: bottomY),
                                endPoint: CGPoint(x: w, y: topY),
                                startColor: UIConstants.Colors.dischargingBlue,
                                endColor: UIConstants.Colors.adapterAmber,
                                width: lineWidth(for: powerFlow.batteryPower)
                            )
                        }
                    }
                }
            }
            .frame(height: 100)
            
            // Right Column (Sinks)
            VStack(spacing: 0) {
                sinkNode(name: "System", icon: "cpu", watts: powerFlow.systemPower, color: UIConstants.Colors.adapterAmber)
                Spacer()
                if powerFlow.topology == .topologyA {
                    sinkNode(name: "Battery", icon: "battery.100.bolt", watts: powerFlow.batteryPower, color: UIConstants.Colors.chargingGreen)
                } else {
                    Color.clear.frame(height: 50)
                }
            }
            .frame(width: 80, height: 100)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 0)
    }
    
    // Scale line width for a clean pipe look
    private func lineWidth(for watts: Double) -> CGFloat {
        if watts <= 0.1 { return 0 }
        let calculated = min(watts * 0.2, 12.0)
        return max(4.0, calculated)
    }
    
    private func sourceNode(name: String, icon: String, watts: Double, color: Color) -> some View {
        nodeView(name: name, icon: icon, watts: watts, color: color)
    }
    
    private func sinkNode(name: String, icon: String, watts: Double, color: Color) -> some View {
        nodeView(name: name, icon: icon, watts: watts, color: color)
    }
    
    private func nodeView(name: String, icon: String, watts: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24)) // Better size for symbols
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                if watts < 0 {
                    Text("--")
                        .font(.system(.subheadline, design: .rounded).monospacedDigit())
                        .fontWeight(.bold)
                } else {
                    Text(String(format: "%.1f", watts))
                        .font(.system(.subheadline, design: .rounded).monospacedDigit())
                        .fontWeight(.bold)
                }
                Text("W")
                    .font(.caption2)
            }
            .foregroundColor(color)
        }
        .frame(height: 50)
    }
}

// Custom Shape for Smooth S-Curve
struct FlowLine: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: startPoint)
        
        // If it's almost horizontal, add a slightly curved path so it doesn't look like a solid pill
        if abs(startPoint.y - endPoint.y) < 1 {
            let midX = startPoint.x + (endPoint.x - startPoint.x) / 2
            path.addQuadCurve(to: endPoint, control: CGPoint(x: midX, y: startPoint.y - 12))
        } else {
            let controlPoint1 = CGPoint(x: startPoint.x + (endPoint.x - startPoint.x) / 2, y: startPoint.y)
            let controlPoint2 = CGPoint(x: startPoint.x + (endPoint.x - startPoint.x) / 2, y: endPoint.y)
            path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
        }
        return path
    }
}

// Thick Gradient Flow Path with Shimmer Effect
struct ThickFlowPath: View {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var startColor: Color
    var endColor: Color
    var width: CGFloat
    
    @State private var isAnimating: Bool = false

    var body: some View {
        FlowLine(startPoint: startPoint, endPoint: endPoint)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        startColor.opacity(isAnimating ? 0.7 : 1.0),
                        endColor.opacity(isAnimating ? 1.0 : 0.7)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: width, lineCap: .round)
            )
            .shadow(color: startColor.opacity(0.3), radius: isAnimating ? 8 : 2, x: 0, y: 0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

import SwiftUI

struct DigitalTwinPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    
    @State private var flowPhase: CGFloat = 0.0
    @AppStorage("powerFlowTwinAnimated") private var isAnimated = true
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 1. Adapter 
                TwinAdapterShape(
                    hasAdapter: powerFlow.adapterPower > 2,
                    adapterPower: powerFlow.adapterPower,
                    name: batteryData?.adapter?.name
                )
                .frame(width: 90, height: 90)
                
                // 2. Wire from Adapter to Mac
                EnergyWire(
                    isActive: powerFlow.adapterPower > 2,
                    direction: .forward, // Power flows from adapter to mac
                    color: Color.blue,
                    phase: flowPhase,
                    isAnimated: isAnimated
                )
                .frame(height: 60)
                
                // 3. Mac System & Battery
                TwinMacBookShape(
                    systemPower: powerFlow.systemPower,
                    batteryPower: powerFlow.batteryPower,
                    isCharging: powerFlow.isCharging,
                    isDischarging: powerFlow.isDischarging,
                    batteryLevel: batteryData?.currentCapacity ?? 0,
                    phase: flowPhase,
                    isAnimated: isAnimated
                )
                .frame(width: 160, height: 110)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 24)
        }
        .frame(minHeight: 140)
        .padding(.vertical, 12)
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimated) { _ in
            startAnimation()
        }
    }
    
    private func startAnimation() {
        if isAnimated {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                flowPhase -= 20.0
            }
        } else {
            flowPhase = 0.0
        }
    }
}

// MARK: - Components

struct TwinAdapterShape: View {
    var hasAdapter: Bool
    var adapterPower: Double
    var name: String?
    
    var body: some View {
        ZStack {
            // Shadow Drop
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.08))
                .offset(y: 6)
                .blur(radius: 6)
            
            // Main Adapter Body (Glass/Plastic Feel)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.windowBackgroundColor)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.1), radius: 1, x: -1, y: -1)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 2, y: 2)
            
            // Sub-surface border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            
            // MagSafe/USB-C Port Edge
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(NSColor.darkGray))
                .frame(width: 4, height: 16)
                .offset(x: 45) // Place port on right
            
            // Power Information Overlay
            VStack(spacing: 2) {
                if hasAdapter {
                    Text(String(format: "%.1f", adapterPower))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.blue)
                    Text("W")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    if let n = name {
                        Text(n.replacingOccurrences(of: "Apple ", with: ""))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                            .lineLimit(1)
                            .padding(.top, 4)
                    }
                } else {
                    Image(systemName: "powerplug")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
        }
        .opacity(hasAdapter ? 1.0 : 0.6)
    }
}

struct TwinMacBookShape: View {
    var systemPower: Double
    var batteryPower: Double
    var isCharging: Bool
    var isDischarging: Bool
    var batteryLevel: Int
    var phase: CGFloat
    var isAnimated: Bool
    
    var body: some View {
        ZStack {
            // Shadow Drop
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.1))
                .offset(y: 8)
                .blur(radius: 8)
            
            // Aluminum Chassis
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.textBackgroundColor))
                .shadow(color: .white.opacity(0.1), radius: 1, x: -1, y: -1)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 4)
            
            // Chassis Border
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            
            // Screen Area (Top Down View perspective logic)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .padding(8)
            
            // Touchpad
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 45, height: 20)
                .offset(y: 35)

            // Content Split (System / Battery)
            HStack(spacing: 8) {
                // Left: System Module
                VStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(String(format: "%.1f", systemPower))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("W")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.textBackgroundColor).opacity(0.5)))
                
                // Internal Cable / Flow Router between System and Battery
                InternalEnergyWire(
                    isCharging: isCharging,
                    isDischarging: isDischarging,
                    phase: phase,
                    isAnimated: isAnimated
                )
                .frame(width: 15)
                
                // Right: Battery Module
                VStack(spacing: 4) {
                    TwinBatteryIcon(
                        level: batteryLevel,
                        isCharging: isCharging,
                        isDischarging: isDischarging
                    )
                    
                    if isCharging || isDischarging {
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text(String(format: "%.1f", batteryPower))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isCharging ? .green : .blue)
                            Text("W")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("\(batteryLevel)%")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.textBackgroundColor).opacity(0.5)))
            }
            .padding(.horizontal, 12)
            .offset(y: -5)
        }
    }
}

enum FlowDirection {
    case forward
    case backward
}

struct EnergyWire: View {
    var isActive: Bool
    var direction: FlowDirection
    var color: Color
    var phase: CGFloat
    var isAnimated: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Static Wire
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                
                // Pulsing Flow
                if isActive {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(
                        color.opacity(0.9),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [12, 12],
                            dashPhase: direction == .forward ? phase : -phase
                        )
                    )
                    .shadow(color: color.opacity(0.6), radius: 3, x: 0, y: 0)
                }
            }
            .clipShape(Rectangle()) // prevent dash leaking
        }
    }
}

struct InternalEnergyWire: View {
    var isCharging: Bool
    var isDischarging: Bool
    var phase: CGFloat
    var isAnimated: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                if isCharging || isDischarging {
                    let flowColor: Color = isCharging ? .green : .blue
                    let dirMulti: CGFloat = isCharging ? 1 : -1
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(
                        flowColor,
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            dash: [6, 6],
                            dashPhase: phase * dirMulti
                        )
                    )
                    .shadow(color: flowColor.opacity(0.5), radius: 2, x: 0, y: 0)
                }
            }
        }
    }
}

struct TwinBatteryIcon: View {
    var level: Int
    var isCharging: Bool
    var isDischarging: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Shell
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.primary.opacity(0.4), lineWidth: 1.5)
                .frame(width: 32, height: 16)
            
            // Knob
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(0.4))
                .frame(width: 3, height: 6)
                .offset(x: 33)
            
            // Core
            let liquidColor: Color = isDischarging ? .blue : (isCharging ? .green : .primary.opacity(0.5))
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(liquidColor)
                    .frame(width: max(0, min(geo.size.width * CGFloat(level) / 100.0, geo.size.width)))
                    .animation(.easeInOut(duration: 0.5), value: level)
            }
            .frame(width: 28, height: 12)
            .padding(.leading, 2)
            
            if isCharging || isDischarging {
                Image(systemName: isCharging ? "bolt.fill" : "arrow.up.left")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(radius: 1)
                    .offset(x: 12)
            }
        }
        .frame(width: 36, height: 16)
    }
}

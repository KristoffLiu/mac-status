import SwiftUI

struct DigitalTwinPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    
    @State private var flowPhase: CGFloat = 0.0
    @AppStorage("powerFlowTwinAnimated") private var isAnimated = true
    @State private var isLidOpen: Bool = false
    @State private var adapterRotation: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 40) {
                
                // 1. 3D 物理适配器 (Power Adapter)
                VStack {
                    Spacer()
                    MacAdapter3DView(
                        power: powerFlow.adapterPower,
                        hasAdapter: powerFlow.adapterPower > 2,
                        adapterName: batteryData?.adapter?.name
                    )
                    // 透视浮动动画
                    .rotation3DEffect(
                        .degrees(15 + adapterRotation),
                        axis: (x: 0.2, y: 1.0, z: 0)
                    )
                    .onHover { hover in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            adapterRotation = hover ? -15 : 0
                        }
                    }
                    Spacer()
                }
                .frame(width: 100)
                .zIndex(2)
                
                // 2. 3D 立体线缆 (Hanging Wire)
                EnergyWire3D(
                    isActive: powerFlow.adapterPower > 2,
                    phase: flowPhase,
                    isAnimated: isAnimated
                )
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 60)
                .offset(x: -20, y: 15) // align with adapter port and mac side
                .zIndex(1)
                
                // 3. 3D 开合 MacBook (MacBook Twin)
                VStack {
                    Spacer()
                    MacBook3DView(
                        systemPower: powerFlow.systemPower,
                        batteryPower: powerFlow.batteryPower,
                        batteryLevel: batteryData?.currentCapacity ?? 0,
                        isCharging: powerFlow.isCharging,
                        isOpen: $isLidOpen
                    )
                    Spacer()
                }
                .frame(width: 200)
                .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 20)
        }
        .frame(minHeight: 180)
        .padding(.vertical, 16)
        .onAppear {
            if isAnimated {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    flowPhase -= 20.0
                }
            }
            // 自动开启屏幕
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isLidOpen = true
                }
            }
        }
    }
}

// MARK: - 3D Adapter

struct MacAdapter3DView: View {
    var power: Double
    var hasAdapter: Bool
    var adapterName: String?
    
    var body: some View {
        ZStack {
            // Shadow Drop corresponding to the 3D tilt
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.15))
                .frame(width: 70, height: 70)
                .offset(x: 10, y: 15)
                .blur(radius: 6)
            
            // Base Block (The Charger Brick)
            ZStack {
                // Back depth face
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(white: 0.85))
                    .frame(width: 70, height: 70)
                    .offset(x: 4, y: 0)
                
                // Main front face
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.95)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 1) // Highlighting edge
                    )
                
                // Details on front face
                if hasAdapter {
                    VStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.8))
                        
                        Text("\(Int(power))W")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(white: 0.4))
                    }
                } else {
                    Image(systemName: "powerplug")
                        .font(.system(size: 24))
                        .foregroundColor(Color(white: 0.8))
                }
            }
            
            // Metal Prongs (Wall side)
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [Color(white: 0.9), Color(white: 0.6)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 6, height: 16)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [Color(white: 0.9), Color(white: 0.6)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 6, height: 16)
            }
            .offset(x: -38, y: 0) // Left side
            .rotation3DEffect(.degrees(15), axis: (x: 0, y: 1, z: 0))
            
            // Port side (USB-C cutout)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.3))
                .frame(width: 6, height: 20)
                .offset(x: 35, y: 0) // Right side
        }
        .opacity(hasAdapter ? 1.0 : 0.4)
    }
}

// MARK: - 3D MacBook Hinge

struct MacBook3DView: View {
    var systemPower: Double
    var batteryPower: Double
    var batteryLevel: Int
    var isCharging: Bool
    
    @Binding var isOpen: Bool
    
    var body: some View {
        ZStack {
            // Environment Shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: 160, height: 30)
                .offset(y: 45)
                .blur(radius: 8)
            
            // The Bottom Chassis (Keyboard part)
            MacBookKeyboardBase(
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                batteryPower: batteryPower
            )
            // Laying flat on table
            .rotation3DEffect(.degrees(70), axis: (x: 1, y: 0, z: 0))
            .offset(y: 20)
            
            // The Screen Lid
            MacBookScreenLid(
                systemPower: systemPower,
                isOpen: isOpen
            )
            // The Hinge Anchor!
            .rotation3DEffect(
                .degrees(isOpen ? 0 : 75), // 0 is open viewing angle, 75 is folded down flat
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom
            )
            .offset(y: -25)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isOpen.toggle()
            }
        }
    }
}

// 底座实体
struct MacBookKeyboardBase: View {
    var batteryLevel: Int
    var isCharging: Bool
    var batteryPower: Double
    
    var body: some View {
        ZStack {
            // Metal unibody
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.8), Color(white: 0.6)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 140, height: 100)
                .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: -1) // highlight top edge
            
            // Keyboard Well
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(white: 0.2)) // black keyboard
                .frame(width: 120, height: 45)
                .offset(y: -15)
            
            // Trackpad
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(white: 0.65))
                .frame(width: 50, height: 35)
                .offset(y: 28)
            
            // Digital Battery Indicator mapped physically inside
            VStack(spacing: 2) {
                // Battery Bar inside base
                let liquidColor: Color = isCharging ? .green : .blue
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(liquidColor.opacity(0.8))
                        .frame(width: max(0, min(geo.size.width * CGFloat(batteryLevel) / 100.0, geo.size.width)))
                }
                .frame(width: 110, height: 4)
                
                HStack {
                    Text("\(batteryLevel)%")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                    if isCharging || batteryPower > 0 {
                        Text("\(String(format: "%.1f", batteryPower))W")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(liquidColor)
                    }
                }
            }
            .offset(y: 4)
            .opacity(0.8)
            // Reverse rotation because the parent rotates 70 degree back
            // So this stands up to face the user slightly!
            .rotation3DEffect(.degrees(-40), axis: (x: 1, y: 0, z: 0))
        }
    }
}

// 屏幕实体
struct MacBookScreenLid: View {
    var systemPower: Double
    var isOpen: Bool
    
    var body: some View {
        ZStack {
            // A Plane (Lid Top) - Metal
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.7), Color(white: 0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 90)
            
            // Apple Logo (Outside)
            Image(systemName: "applelogo")
                .font(.system(size: 20))
                .foregroundColor(Color.white.opacity(0.8))
                .opacity(isOpen ? 0 : 1) // only visible when closed
            
            // Display Plane (Inside)
            if isOpen {
                ZStack {
                    // Bezel
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 136, height: 86)
                    
                    // The glowing screen content
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 80)
                    
                    // Holographic UI on Screen
                    VStack(spacing: 8) {
                        Image(systemName: "cpu")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 4)
                        
                        Text("\(String(format: "%.1f", systemPower)) W")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.8), radius: 2)
                    }
                }
                .transition(.opacity) // prevent flickering
            }
        }
    }
}

// MARK: - 3D Wire Flow

struct EnergyWire3D: View {
    var isActive: Bool
    var phase: CGFloat
    var isAnimated: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Suspended 3D Wire Path
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height - 10),
                        control: CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
                    )
                }
                .stroke(
                    Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                
                // Flowing energy core
                if isActive {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addQuadCurve(
                            to: CGPoint(x: geometry.size.width, y: geometry.size.height - 10),
                            control: CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
                        )
                    }
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            dash: [8, 12],
                            dashPhase: phase
                        )
                    )
                    .shadow(color: .blue.opacity(0.8), radius: 3)
                }
            }
            .rotation3DEffect(.degrees(10), axis: (x: 1, y: 0, z: 0)) // Give wire some X-axis depth
        }
    }
}

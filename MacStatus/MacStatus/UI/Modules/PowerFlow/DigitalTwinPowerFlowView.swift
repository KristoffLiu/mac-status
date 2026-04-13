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
        VStack(spacing: 0) { // Sharing the exact centerline
            // 1. The Screen Lid (Now contains all data for Hero Shot)
            MacBookScreenLid(
                systemPower: systemPower,
                batteryPower: batteryPower,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                isOpen: isOpen
            )
            // HERO HINGE: 0 = Perfect face-on. -88 = Folded shut.
            .rotation3DEffect(
                .degrees(isOpen ? 0 : -88), 
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.3
            )
            .zIndex(2) // ensure screen renders over keyboard when folded
            
            // 2. The Bottom Chassis (Has internal 3D extrusion and rotation)
            MacBookKeyboardBase()
            .zIndex(1)
        }
        // DYNAMIC GLOBAL TILT
        // Open: 0 tilt, perfect straight-on hero shot.
        // Closed: -20 tilt, gentle angle to see the top shell resting on the desk.
        .rotation3DEffect(
            .degrees(isOpen ? 0 : -20), 
            axis: (x: 1, y: 0, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                isOpen.toggle()
            }
        }
        .background(
            // Environment Shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: 160, height: 30)
                .offset(y: 40)
                .blur(radius: 8)
        )
        .offset(y: -10) // center whole system visually
    }
}

// 底座实体 (具备通过多层堆叠生成的物理厚度！彻底隐藏表面)
struct MacBookKeyboardBase: View {
    var body: some View {
        ZStack(alignment: .top) {
            // 利用多层残影构成绝对真实的 3D 厚度 (Extrusion)
            // i=0 是顶部的键盘面，i>0 是它下方的金属机身底座
            ForEach((0...6).reversed(), id: \.self) { i in
                ZStack {
                    // Unibody base
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                // 底层变得更暗，模拟边缘反光和阴影
                                colors: i == 0 ? [Color(white: 0.8), Color(white: 0.6)] : [Color(white: 0.6 - Double(i)*0.05), Color(white: 0.4 - Double(i)*0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 100)
                    
                    // Keyboard elements 仅存在于最表面
                    if i == 0 {
                        // Keyboard Well (black indent)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(white: 0.2))
                            .frame(width: 120, height: 45)
                            .offset(y: -15)
                        
                        // Trackpad
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(white: 0.65))
                            .frame(width: 50, height: 35)
                            .offset(y: 28)
                    }
                    
                    // Front Lip Notch (横切在厚度层上，制造真正的凹槽体积感)
                    if i > 1 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(white: 0.3)) // Notch internal shadow
                            .frame(width: 32, height: 2)
                            .offset(y: 49) // bottom edge
                    }
                }
                // 倾斜 88 度：让键盘面几乎缩减到 0，仅为了保持底边正确的透视拉伸
                .rotation3DEffect(
                    .degrees(88),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.3
                )
                // 神隐级操作：在倾斜过后向 2D Y轴暴力平移，制造不可反驳的侧面物理厚度！
                .offset(y: CGFloat(Double(i) * 1.5))
            }
        }
    }
}

// 屏幕实体 (Hero重点：数据全息呈现于大屏)
struct MacBookScreenLid: View {
    var systemPower: Double
    var batteryPower: Double
    var batteryLevel: Int
    var isCharging: Bool
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
                .font(.system(size: 26))
                .foregroundColor(Color.white.opacity(0.6))
                // Because lid folds -180 degrees backwards, it's upside down!
                .rotationEffect(.degrees(180))
                .opacity(isOpen ? 0 : 1) // only visible when closed
            
            // Display Plane (Inside)
            if isOpen {
                ZStack {
                    // Bezel
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 136, height: 86)
                    
                    let bgGrad = LinearGradient(
                        colors: [Color(white: 0.1), Color(white: 0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(bgGrad)
                        .frame(width: 130, height: 80)
                    
                    // Inspired by user's M3 wallapper: Dynamic floating vertical capsules
                    HStack(spacing: 12) {
                        // System Capsule
                        Capsule()
                            .fill(LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 24, height: CGFloat(max(30, min(70, 30 + systemPower * 0.8))))
                        
                        // Battery Capsule
                        let batCol: [Color] = isCharging ? [.green.opacity(0.8), .mint.opacity(0.6)] : [.blue.opacity(0.5), .purple.opacity(0.4)]
                        Capsule()
                            .fill(LinearGradient(colors: batCol, startPoint: .top, endPoint: .bottom))
                            .frame(width: 24, height: CGFloat(max(20, min(70, 70 * Double(batteryLevel) / 100.0))))
                    }
                    
                    // Holographic UI Overlay on vertical capsules
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.0f", systemPower))W")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 30)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "battery.100")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            Text("\(batteryLevel)%")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 30)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 2)
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

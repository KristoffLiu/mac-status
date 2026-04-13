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
            HStack(spacing: 0) { // Seamless integrated connection
                
                // 1. 适配器 (Power Adapter)
                VStack {
                    Spacer()
                    MacAdapter3DView(
                        power: powerFlow.adapterPower,
                        hasAdapter: powerFlow.adapterPower > 2,
                        adapterName: batteryData?.adapter?.name
                    )
                    .scaleEffect(adapterRotation != 0 ? 1.05 : 1.0)
                    .onHover { hover in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            adapterRotation = hover ? 1 : 0
                        }
                    }
                    Spacer()
                }
                .frame(width: 65)
                .zIndex(2) // Ensure it clips the wire
                
                // 2. 能量连线 (Energy Wire)
                EnergyWire3D(
                    isActive: powerFlow.adapterPower > 2,
                    phase: flowPhase,
                    isAnimated: isAnimated,
                    isCharging: powerFlow.isCharging,
                    batteryLevel: batteryData?.currentCapacity ?? 0
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Overlap perfectly to embed into the ports
                .padding(.horizontal, -1)
                .zIndex(1) // Goes behind adapter and macbook
                
                // 3. 开合 MacBook (MacBook Twin)
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
                .frame(width: 180)
                .zIndex(2) // Ensure it clips the wire
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
        ZStack(alignment: .center) {
            // Shadow Drop
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.12))
                .frame(width: 54, height: 54)
                .offset(y: 3)
                .blur(radius: 5)
            
            // Base Block (The Charger Brick - Sleek Orthogonal)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.95)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(white: 0.85), lineWidth: 0.5)
                )
            
            // Apple style separation line for the AC plug head
            HStack {
                Rectangle().fill(Color(white: 0.85)).frame(width: 1)
                Spacer()
            }
            .frame(width: 54, height: 54)
            .padding(.leading, 15) // Positioned near the prongs
            .mask(RoundedRectangle(cornerRadius: 6))
            
            // Details on front face
            if hasAdapter {
                VStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.7))
                    
                    Text("\(Int(power))W")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.4))
                }
                .offset(x: 4) // adjust rightward to clear plug line
            } else {
                Image(systemName: "powerplug")
                    .font(.system(size: 18))
                    .foregroundColor(Color(white: 0.8))
            }
            
            if hasAdapter {
                // Duckhead Base Block
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.98))
                    .frame(width: 8, height: 22) // More compact
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(white: 0.88), lineWidth: 0.5))
                    .offset(x: -29, y: -8) // Authentic off-center top positioning
                
                // Metal Prongs (Wall side - Flat Horizontal Plates)
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: 3)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: 3)
                }
                .offset(x: -40, y: -8) // Matches the duckhead height
            }
            
            // Port side (USB-C cutout)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.9))
                .frame(width: 4, height: 10)
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color(white: 0.7), lineWidth: 0.5))
                .offset(x: 27) // Snaps beautifully onto the right edge
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
        // Deep drop-hinge using Bottom ZStack anchoring!
        // This flawlessly overlaps the Lid and the Base at their absolute bottom edges.
        ZStack(alignment: .bottom) {
            // The Screen Lid
            MacBookScreenLid(
                systemPower: systemPower,
                batteryPower: batteryPower,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                isOpen: isOpen
            )
            // Screen folds forward to hover over the invisible keyboard
            // By using perspective: 0.0, we use a perfect orthographic projection.
            // When it reaches 90 degrees, it has exactly 0 pixel visual height and vanishes flawlessly!
            .rotation3DEffect(
                .degrees(isOpen ? 0 : -90), 
                axis: (x: 1, y: 0, z: 0),
                anchor: .bottom,
                perspective: 0.0
            )
            .zIndex(1) // Lid dips BEHIND the chassis front lip
            
            // The Bottom Chassis 
            // Stays perfectly static! It visually covers the bottom 9 points of the Screen Lid,
            // creating an authentic MacBook Drop-Hinge effect.
            MacBookKeyboardBase()
            .zIndex(2) // Lip is always conceptually closer to the viewer
        }
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

// 底座实体 (完美恢复：纯正优雅的 2D 矢量边框！绝佳的前侧质感，无厚度拉伸)
struct MacBookKeyboardBase: View {
    var body: some View {
        ZStack(alignment: .top) {
            // Main Front Lip (Smooth metal finish)
            RoundedRectangle(cornerRadius: 3.0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.88), Color(white: 0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 9)
                // Subtle grounding shadow
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            // Thumb Notch for opening
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.5), Color(white: 0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 2)
                .offset(y: 1.5)
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
            // A Plane (Lid Back) - Metal - Sharper corners
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.7), Color(white: 0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 116)
            
            // Display Plane (Inside)
            if isOpen {
                ZStack {
                    // Bezel
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 174, height: 110)
                        .offset(y: -1) // nudge up slightly to clear the drop hinge Overlap
                    
                    let bgGrad = LinearGradient(
                        colors: [Color(white: 0.1), Color(white: 0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(bgGrad)
                        .frame(width: 168, height: 104)
                        .offset(y: -1)
                    
                    // Inspired by user's M3 wallapper: Dynamic floating vertical capsules
                    HStack(spacing: 16) {
                        // System Capsule
                        Capsule()
                            .fill(LinearGradient(colors: [.blue.opacity(0.8), .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 28, height: CGFloat(max(30, min(80, 30 + systemPower * 0.8))))
                        
                        // Battery Capsule
                        let batCol: [Color] = isCharging ? [.green.opacity(0.8), .mint.opacity(0.6)] : [.blue.opacity(0.5), .purple.opacity(0.4)]
                        Capsule()
                            .fill(LinearGradient(colors: batCol, startPoint: .top, endPoint: .bottom))
                            .frame(width: 28, height: CGFloat(max(20, min(80, 80 * Double(batteryLevel) / 100.0))))
                    }
                    
                    // Holographic UI Overlay on vertical capsules
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.0f", systemPower))W")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 34)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "battery.100")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Text("\(batteryLevel)%")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 34)
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
    var isCharging: Bool
    var batteryLevel: Int
    
    var body: some View {
        GeometryReader { geometry in
            // Coordinates tight to the boundaries, allowing the ZStack positioning to handle overlap visually.
            // Mac Base center offset from geometry vertical center is 54 points down.
            let start = CGPoint(x: 2, y: geometry.size.height / 2) // Snug into adapter's Type-C port
            let end = CGPoint(x: geometry.size.width - 2, y: geometry.size.height / 2 + 54) // Hits directly on Mac KeyboardBase port
            
            // To ensure the connection enters perfectly straight at the end:
            // MUST set `control2.y == end.y` so the approach tangent is purely horizontal!
            let control1 = CGPoint(x: geometry.size.width * 0.4, y: start.y + 10)
            let control2 = CGPoint(x: geometry.size.width * 0.75, y: end.y)
            
            ZStack {
                // Suspended Wire Path
                Path { path in
                    path.move(to: start)
                    path.addCurve(to: end, control1: control1, control2: control2)
                }
                .stroke(
                    Color(white: 0.8),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                
                // Flowing energy core
                if isActive {
                    Path { path in
                        path.move(to: start)
                        path.addCurve(to: end, control1: control1, control2: control2)
                    }
                    .stroke(
                        LinearGradient(colors: [.blue.opacity(0.8), .cyan], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            dash: [12, 10],
                            dashPhase: phase
                        )
                    )
                    .shadow(color: .blue.opacity(0.6), radius: 3)
                    
                    // Type-C Head (Start)
                    ZStack {
                        Rectangle()
                            .fill(Color(white: 0.85))
                            .frame(width: 4, height: 4)
                            .offset(x: 4) // strain relief
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(white: 0.75))
                            .frame(width: 8, height: 6)
                            .offset(x: -2) // metal shell sinks into port
                    }
                    .position(x: start.x, y: start.y)
                    
                    // MagSafe 3 Head (End)
                    ZStack {
                        Rectangle()
                            .fill(Color(white: 0.85))
                            .frame(width: 4, height: 4)
                            .offset(x: -8) // strain relief
                            
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(white: 0.85))
                            .frame(width: 12, height: 7)
                            .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.75), lineWidth: 0.5))
                        
                        // LED Indicator inside MagSafe connector
                        let ledColor: Color = (batteryLevel >= 100 && !isCharging) ? .green : .orange
                        Circle()
                            .fill(ledColor)
                            .frame(width: 2.5, height: 2.5)
                    }
                    .position(x: end.x, y: end.y)
                }
            }
        }
    }
}

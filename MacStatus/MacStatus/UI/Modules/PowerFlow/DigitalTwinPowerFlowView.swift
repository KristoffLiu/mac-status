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
                .frame(width: 180) // Matches strictly when closed
                .zIndex(2) // Ensure it clips the wire
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 20)
        }
        .frame(minHeight: 180)
        .padding(.vertical, 16)
        .onAppear {
            // 自动开启屏幕
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Critically damped spring (dampingFraction: 1.0) ensures NO overshoot!
                // This preserves the illusion of the solid 3D rotation, as 2D scale overshoot 
                // would cause "rubbery" distortion.
                withAnimation(.spring(response: 0.7, dampingFraction: 1.0)) {
                    isLidOpen = true
                }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60 FPS
                if isAnimated && powerFlow.adapterPower > 2 {
                    // 功率越高脉冲越快 (最小0.5倍，最大4倍速度)
                    let speedMultiplier = max(0.5, min(4.0, 0.4 + (powerFlow.adapterPower / 60.0)))
                    flowPhase += (2.5 * CGFloat(speedMultiplier))
                    if flowPhase > 10000 { flowPhase -= 10000 }
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
                    .rotationEffect(.degrees(180))
            }
            
            if hasAdapter {
                // Duckhead Base Block
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.98))
                    .frame(width: 8, height: 22) // More compact
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(white: 0.88), lineWidth: 0.5))
                    .offset(x: -29, y: -8) // Authentic off-center top positioning
                
                // SINGLE Metal Prong (Orthographic side projection means they perfectly overlap)
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.55)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 10, height: 4) // Shorter plug
                    .overlay(
                        // The classic US prong circle hole near the tip
                        Circle()
                            .fill(Color(white: 0.4))
                            .frame(width: 2, height: 2)
                            .offset(x: 2) // Adjusted hole position
                    )
                    .offset(x: -38, y: -8) // Matches the duckhead left edge securely
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
            // Emulate 3D physical folding with superior 2D constraints and NO Metal rendering bugs:
            // 1. Z-axis perspective: lid gets narrower when open (x: 0.90)
            // 2. Y-axis folding: collapses to ~4px thickness (0.035 scale) instead of 0px to maintain the Top Shell volume!
            .scaleEffect(
                x: isOpen ? 0.90 : 1.0, 
                y: isOpen ? 0.96 : 0.035, // 0.035 * 116 ≈ 4pt thick top metal shell
                anchor: .bottom
            )
            // 3. Drop Hinge Dynamics: 
            // When opened (0), the lid anchors at the bottom, so its bottom 9pt are covered by the chassis lip.
            // When closed (-9), it shifts UP to sit exquisitely stacked ON TOP of the chassis!
            .offset(y: isOpen ? 0 : -9)
            .zIndex(1) 
            
            // The Bottom Chassis 
            // Stays perfectly static! It visually covers the bottom 9 points of the Screen Lid when open,
            // creating an authentic MacBook Drop-Hinge effect.
            MacBookKeyboardBase()
            .zIndex(2) // Lip is always conceptually closer to the viewer
        }
        .onTapGesture {
            // Unibody metals don't wobble or stretch!
            // Crucial: Use a critically damped spring (dampingFraction = 1.0) so the 2D scaling
            // settles perfectly without overshooting. Overlap/Bounce creates rubber-like deformations.
            withAnimation(.spring(response: 0.6, dampingFraction: 1.0)) {
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
                .frame(width: 180, height: 9) // 闭合时与屏幕尺寸严丝合缝
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
                
                // MacBook Style Lock Screen / Widget Dashboard
                ZStack {
                    // Circular Battery Gauge
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 5)
                            .frame(width: 48, height: 48)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(batteryLevel) / 100.0)
                            .stroke(
                                isCharging ? Color.green : Color.white,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: -1) {
                            Text("\(batteryLevel)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                            Text("%")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .foregroundColor(.white)
                    }
                    .offset(y: -10)
                    
                    // CPU Power Pill
                    HStack(spacing: 4) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 8))
                        Text("\(Int(systemPower)) W")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    // Floating elegantly below the gauge
                    .offset(y: 30)
                }
                .shadow(color: .black.opacity(0.4), radius: 3)
            }
            // Screen contents fade out realistically as the physical lid closes
            .opacity(isOpen ? 1.0 : 0.0)
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
            let start = CGPoint(x: 2, y: geometry.size.height / 2) // Snug into adapter's Type-C port
            
            // Push X precisely inside the Mac's UI boundary (geometry.size.width + 1)
            // Since Mac is zIndex(2), the port structurally "vanishes" into the side wall.
            // Y is tweaked perfectly to center inside the under-taper.
            let end = CGPoint(x: geometry.size.width + 1, y: geometry.size.height / 2 + 43) // Adjusted down slightly from 40
            
            // To ensure the connection enters perfectly straight at the ends AND coils in the middle:
            let coilPath: Path = {
                var path = Path()
                path.move(to: start)
                let topNode = CGPoint(x: geometry.size.width * 0.45, y: start.y - 25)
                let bottomNode = CGPoint(x: geometry.size.width * 0.55, y: end.y + 15)
                
                // Curve 1: Depart horizontally, sweep right and up, arrive at top going LEFT
                path.addCurve(
                    to: topNode,
                    control1: CGPoint(x: start.x + 35, y: start.y),
                    control2: CGPoint(x: topNode.x + 35, y: topNode.y)
                )
                // Curve 2: Depart left, sweep down and arrive at bottom going RIGHT
                path.addCurve(
                    to: bottomNode,
                    control1: CGPoint(x: topNode.x - 35, y: topNode.y),
                    control2: CGPoint(x: bottomNode.x - 35, y: bottomNode.y)
                )
                // Curve 3: Depart right, sweep right and up, arrive horizontally into Mac
                path.addCurve(
                    to: end,
                    control1: CGPoint(x: bottomNode.x + 35, y: bottomNode.y),
                    control2: CGPoint(x: end.x - 35, y: end.y)
                )
                return path
            }()
            
            ZStack {
                // Braided Wire Simulation
                let baseColor = isActive ? Color(white: 0.15) : Color(white: 0.8)
                let weaveColor1 = isActive ? Color(white: 0.25) : Color(white: 0.9)
                let weaveColor2 = isActive ? Color(white: 0.1) : Color(white: 0.7)
                
                // 1. Base Cord
                coilPath.stroke(baseColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                
                // 2. Weave Layer 1 (Diagonal outer stitching)
                coilPath.stroke(weaveColor1, style: StrokeStyle(lineWidth: 4.5, lineCap: .butt, dash: [2, 3]))
                
                // 3. Weave Layer 2 (Inner core texture to create 3D cross-hatch depth)
                coilPath.stroke(weaveColor2, style: StrokeStyle(lineWidth: 2.0, lineCap: .butt, dash: [3, 2], dashPhase: 2))
                
                // Simple Flow Animation
                if isActive {
                    // One-at-a-time white pulse with aura
                    coilPath.stroke(
                        Color.white,
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            dash: [25, 400], // 25pt pulse, 400pt gap ensures only ONE pulse is visible
                            dashPhase: -phase // flows towards the Mac
                        )
                    )
                    .shadow(color: .white.opacity(0.8), radius: 3) // Aura
                    
                    // Type-C Head (Start)
                    ZStack {
                        Rectangle()
                            .fill(Color(white: 0.15)) // Match cable dark color
                            .frame(width: 4, height: 3)
                            .offset(x: 4) // strain relief
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(white: 0.75))
                            .frame(width: 8, height: 5)
                            .offset(x: -2) // metal shell sinks into port
                    }
                    .position(x: start.x, y: start.y)
                    
                    // MagSafe 3 Head (End)
                    ZStack {
                        Rectangle()
                            .fill(Color(white: 0.15)) // Match cable dark color
                            .frame(width: 6, height: 3) // Strain relief extended to bridge port
                            .offset(x: -10)
                            
                        RoundedRectangle(cornerRadius: 1.0)
                            .fill(Color(white: 0.85))
                            .frame(width: 14, height: 5)
                            .overlay(RoundedRectangle(cornerRadius: 1.0).stroke(Color(white: 0.75), lineWidth: 0.5))
                        
                        // LED Indicator inside MagSafe connector
                        let ledColor: Color = (batteryLevel >= 100 && !isCharging) ? .green : .orange
                        Circle()
                            .fill(ledColor)
                            .frame(width: 2.0, height: 2.0)
                    }
                    .position(x: end.x, y: end.y)
                }
            }
        }
    }
}

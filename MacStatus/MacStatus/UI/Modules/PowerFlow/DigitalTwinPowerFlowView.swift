import SwiftUI
import Combine
struct DigitalTwinPowerFlowView: View {
    var powerFlow: PowerFlowData
    var batteryData: BatteryData?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppPreferenceKeys.powerFlowTwinAnimated) private var isAnimatedSetting = true
    @ObservedObject private var energyManager = EnergyEfficiencyManager.shared
    private var isAnimated: Bool { isAnimatedSetting && !reduceMotion && energyManager.appState == .active && !energyManager.policy.sleeping }
    @AppStorage(AppPreferenceKeys.twinCableStyle) private var twinCableStyle = "p"
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
                        hasAdapter: powerFlow.hasAdapter,
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
                    isActive: powerFlow.hasAdapter,
                    adapterPower: powerFlow.adapterSupplyPower,
                    isAnimated: isAnimated,
                    isCharging: powerFlow.isCharging,
                    batteryLevel: batteryData?.currentCapacity ?? 0,
                    cableStyle: twinCableStyle,
                    onToggleStyle: {
                        twinCableStyle = (twinCableStyle == "p") ? "j" : "p"
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Overlap perfectly to embed into the ports
                .padding(.horizontal, -1)
                .zIndex(1) // Goes behind adapter and macbook
                
                // 3. 开合 MacBook / Mac Desktop (Mac Twin)
                VStack {
                    Spacer()
                    MacDeviceSystem3D(
                        systemPower: powerFlow.systemPower,
                        batteryPower: powerFlow.directionalBatteryPower,
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

// MARK: - 3D Devices Router

struct MacDeviceSystem3D: View {
    var systemPower: Double
    var batteryPower: Double
    var batteryLevel: Int
    var isCharging: Bool
    
    @Binding var isOpen: Bool
    @AppStorage(AppPreferenceKeys.twinDeviceType) private var deviceType: String = "mbp"
    
    var body: some View {
        switch deviceType {
        case "mini":
            MacMini3DView(systemPower: systemPower, batteryLevel: batteryLevel, isCharging: isCharging)
                .scaleEffect(0.85)
                .offset(y: 20)
        case "studio":
            MacStudio3DView(systemPower: systemPower, batteryLevel: batteryLevel, isCharging: isCharging)
                .scaleEffect(0.82)
                .offset(y: 20)
        case "imac":
            iMac3DView(systemPower: systemPower, batteryLevel: batteryLevel, isCharging: isCharging)
                .scaleEffect(0.68)
                .offset(y: 15)
        case "mba":
            MacBook3DView(
                systemPower: systemPower,
                batteryPower: batteryPower,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                isOpen: $isOpen
            )
            .scaleEffect(0.93)
        case "neo":
            MacBook3DView(
                systemPower: systemPower,
                batteryPower: batteryPower,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                isOpen: $isOpen
            )
            .scaleEffect(0.85)
        default:
            MacBook3DView(
                systemPower: systemPower,
                batteryPower: batteryPower,
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                isOpen: $isOpen
            )
        }
    }
}

// MARK: - 3D Desktop Macs
struct MacMini3DView: View {
    var systemPower: Double
    var batteryLevel: Int
    var isCharging: Bool
    
    @AppStorage(AppPreferenceKeys.twinMacColor) private var twinMacColor: String = "silver"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Holographic HUD
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if isCharging { Image(systemName: "bolt.fill").font(.system(size: 18)).foregroundColor(.green) }
                    Text("\(batteryLevel)").font(.system(size: 42, weight: .heavy, design: .rounded))
                    Text("%").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.secondary)
                }
                HStack(spacing: 4) { Image(systemName: "cpu"); Text("System \(Int(systemPower)) W") }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
            }
            .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 6, x: 0, y: 0)
            .offset(y: -75)
            .zIndex(1)
            
            // M4 Mac Mini Base Vent
            Path { path in
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 90, y: 0))
                path.addLine(to: CGPoint(x: 82, y: 6))
                path.addLine(to: CGPoint(x: 18, y: 6))
            }
            .fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .top, endPoint: .bottom))
            .frame(width: 100, height: 6)
            .offset(y: 6)
            .zIndex(1)
            
            // Mac Mini M4 Body
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                    .fill(LinearGradient(colors: TwinMacColor.baseColors(for: twinMacColor), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 38)
                    .overlay(
                        // Front IO (2 Type-C, LED, Headphone)
                        HStack(spacing: 0) {
                            HStack(spacing: 10) {
                                Capsule().fill(Color(white: 0.15)).frame(width: 3.5, height: 10)
                                Capsule().fill(Color(white: 0.15)).frame(width: 3.5, height: 10)
                            }
                            .padding(.leading, 18)
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: 10) {
                                Circle().fill(Color.white).frame(width: 1.5, height: 1.5).shadow(color: .white, radius: 2)
                                Circle().fill(Color(white: 0.15)).frame(width: 3.5, height: 3.5)
                            }
                            .padding(.trailing, 18)
                        }
                        .padding(.bottom, 8), alignment: .bottom
                    )
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 3)
            .zIndex(2)
        }
        .background(
            Ellipse().fill(Color.black.opacity(0.2)).frame(width: 130, height: 20).offset(y: 45).blur(radius: 6)
        )
        .offset(y: 5)
    }
}

struct MacStudio3DView: View {
    var systemPower: Double
    var batteryLevel: Int
    var isCharging: Bool
    
    @AppStorage(AppPreferenceKeys.twinMacColor) private var twinMacColor: String = "silver"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Holographic HUD
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if isCharging { Image(systemName: "bolt.fill").font(.system(size: 18)).foregroundColor(.green) }
                    Text("\(batteryLevel)").font(.system(size: 42, weight: .heavy, design: .rounded))
                    Text("%").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.secondary)
                }
                HStack(spacing: 4) { Image(systemName: "cpu"); Text("System \(Int(systemPower)) W") }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
            }
            .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 6, x: 0, y: 0)
            .offset(y: -75)
            .zIndex(1)
            
            // Mac Studio Body
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                    .fill(LinearGradient(colors: TwinMacColor.baseColors(for: twinMacColor), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 154, height: 60)
                    .overlay(
                        // Front port details: 2 USB-C (left) + 1 SDXC (right) + LED
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Capsule().fill(Color(white: 0.15)).frame(width: 4.5, height: 14)
                                Capsule().fill(Color(white: 0.15)).frame(width: 4.5, height: 14)
                            }
                            .padding(.leading, 18)
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 1.5).fill(Color(white: 0.15)).frame(width: 20, height: 3)
                            
                            Circle().fill(Color.white).frame(width: 1.5, height: 1.5)
                                .shadow(color: .white, radius: 2)
                                .padding(.leading, 6).padding(.trailing, 14)
                        }
                        .padding(.bottom, 10), alignment: .bottom
                    )
                // Black base grill
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 0))
                    path.addLine(to: CGPoint(x: 130, y: 0))
                    path.addLine(to: CGPoint(x: 120, y: 6))
                    path.addLine(to: CGPoint(x: 20, y: 6))
                }
                .fill(LinearGradient(colors: [Color(white: 0.15), Color(white: 0.05)], startPoint: .top, endPoint: .bottom))
                .frame(width: 140, height: 6)
            }
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
            .zIndex(2)
        }
        .background(
            Ellipse().fill(Color.black.opacity(0.25)).frame(width: 150, height: 26).offset(y: 45).blur(radius: 8)
        )
        .offset(y: 5)
    }
}

// MARK: - iMac 3D View
struct iMac3DView: View {
    var systemPower: Double
    var batteryLevel: Int
    var isCharging: Bool
    
    @AppStorage(AppPreferenceKeys.twinMacColor) private var twinMacColor: String = "silver"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // iMac stand (behind the screen)
            Path { path in
                path.move(to: CGPoint(x: 75, y: 0))
                path.addLine(to: CGPoint(x: 95, y: 0))
                path.addLine(to: CGPoint(x: 105, y: 40))
                path.addLine(to: CGPoint(x: 65, y: 40))
            }
            .fill(LinearGradient(colors: TwinMacColor.baseColors(for: twinMacColor), startPoint: .top, endPoint: .bottom))
            .frame(width: 170, height: 40)
            .shadow(color: .black.opacity(0.15), radius: 2)
            .offset(y: 35)
            
            // Screen & Chin unibody
            VStack(spacing: 0) {
                // Screen (White bezels with dark screen inside)
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 170, height: 100)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 10,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 10
                            )
                        )
                    
                    Rectangle()
                        .fill(Color(white: 0.05)) // Screen glass
                        .frame(width: 160, height: 90)
                        
                    // Data inside screen
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            if isCharging { Image(systemName: "bolt.fill").font(.system(size: 14)).foregroundColor(.green) }
                            Text("\(batteryLevel)").font(.system(size: 32, weight: .heavy, design: .rounded))
                            Text("%").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.7))
                        }
                        HStack(spacing: 4) { Image(systemName: "cpu"); Text("System \(Int(systemPower)) W") }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                    }
                    .foregroundColor(.white)
                }
                
                // iMac Chin
                Rectangle()
                    .fill(LinearGradient(colors: TwinMacColor.lidColors(for: twinMacColor), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 170, height: 35)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 12,
                            topTrailingRadius: 0
                        )
                    )
            }
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
            .zIndex(2)
        }
        .offset(y: 5)
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
            
            // Hovering Info HUD when Closed
            if !isOpen {
                VStack(spacing: 0) {
                    // Huge Battery Percentage
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        if isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        Text("\(batteryLevel)")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                        Text("%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Elegantly understated CPU Power
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                        Text("System \(Int(systemPower)) W")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                }
                .shadow(color: Color(NSColor.windowBackgroundColor).opacity(0.8), radius: 6, x: 0, y: 0) // diffuse glow for text contrast
                .offset(y: -40) // lowered slightly
                .zIndex(0) // Pushed BEHIND the screen lid (zIndex 1) to prevent clipping overflow when opening/closing
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.4).delay(0.15)),
                    removal: .opacity.animation(.easeIn(duration: 0.2)) // fast fade out behind the rising screen
                ))
            }
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

// MARK: - Mac Colors

struct TwinMacColor {
    static func lidColors(for color: String) -> [Color] {
        switch color {
        case "spaceGray": return [Color(white: 0.55), Color(white: 0.35)]
        case "midnight": return [Color(red: 0.22, green: 0.23, blue: 0.28), Color(red: 0.12, green: 0.13, blue: 0.18)]
        case "starlight": return [Color(red: 0.85, green: 0.82, blue: 0.76), Color(red: 0.65, green: 0.62, blue: 0.56)]
        case "peachPink": return [Color(red: 0.95, green: 0.81, blue: 0.83), Color(red: 0.86, green: 0.69, blue: 0.72)]
        case "citrusYellow": return [Color(red: 0.92, green: 0.86, blue: 0.50), Color(red: 0.82, green: 0.75, blue: 0.40)]
        case "indigoBlue": return [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.25, green: 0.30, blue: 0.40)]
        case "blue": return [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]
        case "green": return [Color.green.opacity(0.8), Color.green.opacity(0.6)]
        case "pink": return [Color.pink.opacity(0.8), Color.pink.opacity(0.6)]
        case "yellow": return [Color.yellow.opacity(0.8), Color.yellow.opacity(0.6)]
        case "orange": return [Color.orange.opacity(0.8), Color.orange.opacity(0.6)]
        case "purple": return [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]
        case "silver": fallthrough
        default: return [Color(white: 0.7), Color(white: 0.5)]
        }
    }
    
    static func baseColors(for color: String) -> [Color] {
        switch color {
        case "spaceGray": return [Color(white: 0.65), Color(white: 0.40)]
        case "midnight": return [Color(red: 0.25, green: 0.26, blue: 0.31), Color(red: 0.15, green: 0.16, blue: 0.21)]
        case "starlight": return [Color(red: 0.90, green: 0.88, blue: 0.82), Color(red: 0.68, green: 0.65, blue: 0.59)]
        case "peachPink": return [Color(red: 0.90, green: 0.78, blue: 0.80), Color(red: 0.80, green: 0.65, blue: 0.68)]
        case "citrusYellow": return [Color(red: 0.88, green: 0.82, blue: 0.45), Color(red: 0.78, green: 0.70, blue: 0.35)]
        case "indigoBlue": return [Color(red: 0.45, green: 0.50, blue: 0.60), Color(red: 0.30, green: 0.35, blue: 0.45)]
        case "blue": return [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]
        case "green": return [Color.green.opacity(0.8), Color.green.opacity(0.6)]
        case "pink": return [Color.pink.opacity(0.8), Color.pink.opacity(0.6)]
        case "yellow": return [Color.yellow.opacity(0.8), Color.yellow.opacity(0.6)]
        case "orange": return [Color.orange.opacity(0.8), Color.orange.opacity(0.6)]
        case "purple": return [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]
        case "silver": fallthrough
        default: return [Color(white: 0.88), Color(white: 0.55)]
        }
    }
}

// 底座实体
struct MacBookKeyboardBase: View {
    @AppStorage(AppPreferenceKeys.twinMacColor) private var twinMacColor: String = "silver"
    @AppStorage(AppPreferenceKeys.twinDeviceType) private var deviceType: String = "mbp"
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main Front Lip
            let isMBA = deviceType == "mba"
            let isNeo = deviceType == "neo"
            
            RoundedRectangle(cornerRadius: 3.0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: TwinMacColor.baseColors(for: twinMacColor),
                        startPoint: .top, endPoint: .bottom
                    )
                )
                // MBA is thinner at the front (wedge shape logic handled by thin height)
                // Neo is widened to 172 to comfortably hold the 160 lid with solid borders
                .frame(width: isNeo ? 172 : 180, height: isMBA ? 6 : 9)
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
    
    @AppStorage(AppPreferenceKeys.twinMacColor) private var twinMacColor: String = "silver"
    @AppStorage(AppPreferenceKeys.twinDeviceType) private var deviceType: String = "mbp"
    
    var body: some View {
        let isNeo = deviceType == "neo"
        
        ZStack {
            // A Plane (Lid Back)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: TwinMacColor.lidColors(for: twinMacColor),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: isNeo ? 160 : 180, height: isNeo ? 104 : 116)
            
            // Display Plane (Inside)
            ZStack {
                // Bezel
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black)
                    .frame(width: 174, height: 110)
                    .offset(y: -1) // nudge up slightly to clear the drop hinge Overlap
                
                // macOS Native Default Wallpaper Vibes (Sonoma/Monterey abstract)
                let bgGrad = LinearGradient(
                    colors: [Color(red: 0.2, green: 0.1, blue: 0.4), Color(red: 0.0, green: 0.3, blue: 0.5)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(bgGrad)
                    .frame(width: 168, height: 104)
                    .offset(y: -1)
                
                // MacBook Style Lock Screen / Widget Dashboard
                ZStack(alignment: .topLeading) {
                    // Top Menu Bar
                    VStack {
                        HStack {
                            Spacer()
                            
                            // Miniature macOS Status Bar Battery
                            ZStack(alignment: .leading) {
                                // Main body container
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                                    .frame(width: 10, height: 5)
                                    
                                // Battery level fill
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(isCharging ? Color.green : Color.white)
                                    .frame(width: max(0, CGFloat(batteryLevel) / 100.0 * 8), height: 3)
                                    .padding(.leading, 1)
                                
                                // Battery terminal nip
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 1, height: 2)
                                    .offset(x: 10.5)
                                
                                if isCharging {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 3))
                                        .foregroundColor(batteryLevel >= 100 ? .black : .white)
                                        .offset(x: 3.5)
                                }
                            }
                            .frame(width: 12, height: 5)
                        }
                        .padding(.trailing, 4)
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                    
                    // Top-Left Desktop Widget
                    // Redesigned to native macOS Sonoma style: clean typography, frosted glass, large readable values
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.black.opacity(0.2)) // subtle blur/darken plane
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.05)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // Top row: Graphic / Context
                            Image(systemName: "bolt.batteryblock.fill")
                                .font(.system(size: 7))
                                .foregroundColor(isCharging ? .green : .white.opacity(0.9))
                                .padding(.bottom, 3)
                            
                            // Large Battery Percentage Typography
                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text("\(batteryLevel)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("%")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer(minLength: 0)
                            
                            // System Power Status
                            HStack(spacing: 2) {
                                Image(systemName: "cpu")
                                    .font(.system(size: 5, weight: .bold))
                                Text("\(Int(systemPower)) W")
                                    .font(.system(size: 6, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                    }
                    .frame(width: 48, height: 48)
                    .padding(.leading, 8)
                    .padding(.top, 14) // Offset clear below the top menu bar
                }
                .frame(width: 168, height: 104) // STRICTLY BOUND TO SCREEN TO PREVENT SPACERS FROM EXPANDING MACBOOK LAYOUT


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
    var adapterPower: Double
    var isAnimated: Bool
    var isCharging: Bool
    var batteryLevel: Int
    var cableStyle: String
    var onToggleStyle: (() -> Void)? = nil
    
    @State private var phase: CGFloat = 0.0
    @AppStorage(AppPreferenceKeys.twinDeviceType) private var deviceType: String = "mbp"
    
    var body: some View {
        GeometryReader { geometry in
            let start = CGPoint(x: 2, y: geometry.size.height / 2) // Adapter Type-C
            
            // Adjust port location based on device height
            let portYOffset: CGFloat = {
                if deviceType == "mini" { return 45 } // further down because of offset
                if deviceType == "studio" { return 43 }
                if deviceType == "imac" { return 40 }
                if deviceType == "neo" { return 34 } // scaled from center moves bottom up
                if deviceType == "mba" { return 39 } // scaled from center
                return 43 // MBP
            }()
            
            let endX: CGFloat = {
                if ["mini", "studio", "imac"].contains(deviceType) {
                    // Extend wire far enough to reliably hide completely behind the machine
                    return geometry.size.width + 60
                }
                if deviceType == "neo" {
                    // Neo base shrinks significantly inwards
                    return geometry.size.width + 8
                }
                if deviceType == "mba" {
                    // MBA base shrinks slightly inwards
                    return geometry.size.width + 7
                }
                // MBP/MBA base gap width approximation
                return geometry.size.width + 1
            }()
            
            let end = CGPoint(x: endX, y: geometry.size.height / 2 + portYOffset)
            
            // To ensure the connection enters perfectly straight at the ends AND coils in the middle:
            let coilPath: Path = {
                var path = Path()
                path.move(to: start)
                
                if cableStyle == "j" {
                    // J-type meticulous routing
                    let coilStartX = geometry.size.width * 0.42
                    let coilEndX = geometry.size.width * 0.58
                    
                    path.addLine(to: CGPoint(x: coilStartX, y: start.y))
                    
                    let loops = 6
                    let loopHeightY = (end.y - start.y)
                    
                    for i in 0..<loops {
                        let t1 = CGFloat(i) / CGFloat(loops)
                        let t2 = CGFloat(i + 1) / CGFloat(loops)
                        
                        let currentX = coilStartX + t1 * (coilEndX - coilStartX)
                        let nextX = coilStartX + t2 * (coilEndX - coilStartX)
                        let currentY = start.y + t1 * loopHeightY
                        let nextY = start.y + t2 * loopHeightY
                        
                        // Draw tight spring-like loops spanning the gap
                        path.addCurve(
                            to: CGPoint(x: nextX, y: nextY),
                            control1: CGPoint(x: currentX + 26, y: currentY - 14),
                            control2: CGPoint(x: nextX - 26, y: nextY + 14)
                        )
                    }
                    
                    path.addLine(to: end)
                } else {
                    // P-type sweeping loose curve
                    let topNode = CGPoint(x: geometry.size.width * 0.45, y: start.y - 25)
                    let bottomNode = CGPoint(x: geometry.size.width * 0.55, y: end.y + 15)
                    
                    path.addCurve(
                        to: topNode,
                        control1: CGPoint(x: start.x + 35, y: start.y),
                        control2: CGPoint(x: topNode.x + 35, y: topNode.y)
                    )
                    path.addCurve(
                        to: bottomNode,
                        control1: CGPoint(x: topNode.x - 35, y: topNode.y),
                        control2: CGPoint(x: bottomNode.x - 35, y: bottomNode.y)
                    )
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: bottomNode.x + 35, y: bottomNode.y),
                        control2: CGPoint(x: end.x - 35, y: end.y)
                    )
                }
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
                    if !["mini", "studio", "imac"].contains(deviceType) {
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
            .contentShape(Rectangle()) // Expand hit area
            // Tap on the right side area or generally on the cable bounds to toggle
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    onToggleStyle?()
                }
            }
        }
        .task(id: isAnimated && isActive) {
            guard isAnimated && isActive else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                guard !Task.isCancelled else { return }
                let speedMultiplier = max(0.5, min(4.0, 0.4 + (adapterPower / 60.0)))
                phase += 4.125 * CGFloat(speedMultiplier)
                if phase > 10000 { phase -= 10000 }
            }
        }
    }
}

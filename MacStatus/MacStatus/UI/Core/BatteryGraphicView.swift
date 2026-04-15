import SwiftUI

struct BatteryGraphicView: View {
    var capacity: Int
    var isCharging: Bool
    var isPowered: Bool = false  // adapter connected (covers bypass/passthrough)

    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false

    // Configurable styles
    var isColored: Bool = false
    var chargingStyle: String = "bolt"  // "none", "bolt", "classic", "plug"
    var showNumber: Bool = false
    var isIOSStyle: Bool = false
    
    // Unified Battery Size
    var width: CGFloat = 23.5   // Exact native shell body width (excluding terminal)
    var height: CGFloat = 11.5  // Increased height slightly
    
    var body: some View {
        let percentage = Double(capacity) / 100.0
        
        let isCritical = capacity <= 20
        let showLowPowerColor = isCritical && iconLowPowerColor

        let fillColor: Color = {
            if isColored {
                // Capacity-based coloring: green > 50%, yellow 20–50%, red ≤ 20%
                if capacity > 50 { return .green }
                else if capacity > 20 { return .yellow }
                else { return .red }
            } else {
                return showLowPowerColor ? .red : .primary
            }
        }()
            
        // Border color must be absolutely identical in colored and monochrome modes!
        // We use a solid primary color to eliminate any "transparency" feeling the user pointed out.
        let strokeColor: Color = Color.primary
        let strokeWidth: CGFloat = 1.0
        let insets: CGFloat = isIOSStyle ? 0 : 1.5 // macOS has 1.5pt gap, iOS has none
        
        let maxFillWidth = max(0, width - (insets * 2))
        let fillWidth = maxFillWidth * percentage
        let iosBackgroundColor: Color = (isColored ? fillColor : .primary).opacity(0.2)
        
        // Exact Apple geometry squircles
        let shellCornerRadius: CGFloat = 3.0
        let fillCornerRadius: CGFloat = isIOSStyle ? shellCornerRadius : 1.5
        
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                // Outer Shell
                if isIOSStyle {
                    RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                        .fill(iosBackgroundColor)
                        .frame(width: width, height: height)
                } else {
                    RoundedRectangle(cornerRadius: shellCornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .frame(width: width, height: height)
                }
                
                // Inner Fill
                RoundedRectangle(cornerRadius: fillCornerRadius, style: .continuous)
                    .fill(fillColor)
                    .frame(width: fillWidth, height: height - (insets * 2))
                    .padding(.leading, insets)
                    .animation(.easeInOut, value: percentage)
                
                // Inner Content: number OR charging indicator (mutually exclusive)
                if showNumber {
                    Text("\(capacity)")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(isColored ? (capacity > 50 || capacity <= 20 ? .white : .black) : .black)
                        .blendMode(isColored ? .normal : .destinationOut)
                        .frame(width: width, alignment: .center)
                } else if (isCharging || isPowered) && chargingStyle != "none" {
                    switch chargingStyle {
                    case "classic":
                        // Uniform knockout border via shadow spread
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .shadow(color: .black, radius: 0.8)
                            .shadow(color: .black, radius: 0.8)
                            .shadow(color: .black, radius: 0.8)
                            .blendMode(.destinationOut)
                            .frame(width: width, alignment: .center)
                        // Solid bolt fill (same size, drawn on top)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: width, alignment: .center)
                    case "plug":
                        // Uniform knockout border via shadow spread
                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .rotationEffect(.degrees(-90))
                            .offset(x: 4)
                            .foregroundColor(.black)
                            .shadow(color: .black, radius: 0.8)
                            .shadow(color: .black, radius: 0.8)
                            .shadow(color: .black, radius: 0.8)
                            .blendMode(.destinationOut)
                            .frame(width: width, alignment: .center)
                        // Solid plug fill (same size, drawn on top)
                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .rotationEffect(.degrees(-90))
                            .offset(x: 4)
                            .foregroundColor(.white)
                            .frame(width: width, alignment: .center)
                    default: // "bolt"
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(isColored ? (capacity > 50 || capacity <= 20 ? .white : .black) : .black)
                            .blendMode(isColored ? .normal : .destinationOut)
                            .frame(width: width, alignment: .center)
                    }
                }
            }
            .compositingGroup()
            
            // Terminal Edge (Battery Tip)
            Capsule(style: .continuous)
                .fill(isIOSStyle ? iosBackgroundColor : strokeColor)
                .frame(width: 2.0, height: 3.5)
                .padding(.leading, 1) // Ensures terminal and body do not touch
        }
        .padding(.leading, 1)
        .padding(.trailing, 2)
        .padding(.vertical, 2)
    }
}

// A view explicitly for extracting the battery isolated graphic
struct IsolatedBatteryGraphicRenderer: View {
    @ObservedObject var viewModel: StatusViewModel
    
    @AppStorage("batteryShellStyle") private var batteryShellStyle = "native"
    @AppStorage("batteryFillStyle") private var batteryFillStyle = "monochrome"
    @AppStorage("batteryInnerContent") private var batteryInnerContent = "none"
    @AppStorage("batteryChargingIndicator") private var batteryChargingIndicator = "bolt"

    var body: some View {
        Group {
            if batteryShellStyle != "hidden" {
                BatteryGraphicView(
                    capacity: viewModel.currentCapacity,
                    isCharging: viewModel.isCharging,
                    isPowered: viewModel.batteryData.adapter != nil,
                    isColored: batteryFillStyle == "status_color",
                    chargingStyle: batteryChargingIndicator,
                    showNumber: batteryInnerContent == "inside",
                    isIOSStyle: batteryShellStyle == "ios"
                )
            }
        }
        .fixedSize()
    }
}

// A view that combines the battery graphic with other items for the Menu Bar natively
struct MenuBarLabelRendererView: View {
    @ObservedObject var viewModel: StatusViewModel
    var generatedMenuImage: NSImage?
    
    @AppStorage("menuBarPowerStyle") private var menuBarPowerStyle: MenuBarPowerStyle = .graphic
    @AppStorage("batteryLayout") private var batteryLayout = "left"
    
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = false
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    @AppStorage("batteryInnerContent") private var batteryInnerContent = "none"
    
    @AppStorage("showMaxCapacity") private var showMaxCapacity = false
    @AppStorage("showMacOSCapacity") private var showMacOSCapacity = false
    @AppStorage("showMacOSCondition") private var showMacOSCondition = false
    @AppStorage("showCycles") private var showCycles = false
    
    @AppStorage("showTemperature") private var showTemperature = false
    @AppStorage("showTimeRemaining") private var showTimeRemaining = false
    @AppStorage("showAmperage") private var showAmperage = false
    @AppStorage("showVoltage") private var showVoltage = false
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showSystemLoad") private var showSystemLoad = false
    
    @AppStorage("showAdapterCurrent") private var showAdapterCurrent = false
    @AppStorage("showAdapterVoltage") private var showAdapterVoltage = false
    @AppStorage("showAdapterPower") private var showAdapterPower = false
    
    @AppStorage("showAlDenteCalibration") private var showAlDenteCalibration = false
    @AppStorage("showAlDenteOverheat") private var showAlDenteOverheat = false
    @AppStorage("showAlDenteSailing") private var showAlDenteSailing = false
    @AppStorage("showAlDenteFull") private var showAlDenteFull = false
    
    // Spacing
    @AppStorage("menuItemSpacing") private var menuItemSpacing: Double = 4
    @AppStorage("mainIconGroupSpacing") private var mainIconGroupSpacing: Double = 4

    // Battery Man
    @AppStorage("batteryManLegLength") private var batteryManLegLength: BatteryManLegLength = .normal
    @AppStorage("batteryManShowFace") private var batteryManShowFace = false
    @AppStorage("batteryManShowArms") private var batteryManShowArms = false
    @AppStorage("batteryManShowPosture") private var batteryManShowPosture = false
    @AppStorage("batteryManShowAccessory") private var batteryManShowAccessory = false
    @AppStorage("batteryManFaceStyle") private var batteryManFaceStyle: BatteryManFaceStyle = .outline

    var body: some View {
        HStack(spacing: CGFloat(menuItemSpacing)) {
            // Main Icon Group
            HStack(spacing: CGFloat(mainIconGroupSpacing)) {
                if menuBarPowerStyle == .graphic {
                    if batteryLayout == "left", let image = generatedMenuImage { Image(nsImage: image) }

                    if batteryInnerContent == "outside" { Text("\(viewModel.currentCapacity)%") }
                    if showChargingStatus && viewModel.isCharging { Image(systemName: "bolt.fill") }

                    if batteryLayout == "right", let image = generatedMenuImage { Image(nsImage: image) }
                } else if menuBarPowerStyle == .batteryMan {
                    if batteryLayout == "left" {
                        BatteryManView(
                            capacity: viewModel.currentCapacity,
                            isCharging: viewModel.isCharging,
                            isColored: false,
                            showBolt: true,
                            legLength: batteryManLegLength,
                            showFace: batteryManShowFace,
                            showArms: batteryManShowArms,
                            showPosture: batteryManShowPosture,
                            showAccessory: batteryManShowAccessory,
                            faceStyle: batteryManFaceStyle
                        )
                    }
                    if showPercentage { Text("\(viewModel.currentCapacity)%") }
                    if showChargingStatus && viewModel.isCharging { Image(systemName: "bolt.fill") }
                    if batteryLayout == "right" {
                        BatteryManView(
                            capacity: viewModel.currentCapacity,
                            isCharging: viewModel.isCharging,
                            isColored: false,
                            showBolt: true,
                            legLength: batteryManLegLength,
                            showFace: batteryManShowFace,
                            showArms: batteryManShowArms,
                            showPosture: batteryManShowPosture,
                            showAccessory: batteryManShowAccessory,
                            faceStyle: batteryManFaceStyle
                        )
                    }
                } else if menuBarPowerStyle == .symbolic {
                    Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")
                        .symbolRenderingMode(.hierarchical)
                    if showPercentage { Text("\(viewModel.currentCapacity)%") }
                } else if menuBarPowerStyle == .textOnly {
                    Text("\(viewModel.currentCapacity)%")
                        .fontWeight(.bold)
                }
            }
            
            // Health
            if showMaxCapacity { HStack(spacing: 2) { Image(systemName: "stethoscope"); Text("H:\(viewModel.batteryData.appleRawMaxCapacity ?? 0)%") } }
            if showMacOSCapacity { HStack(spacing: 2) { Image(systemName: "info.circle"); Text("S:\(viewModel.batteryData.appleMaxCapacity ?? 0)%") } }
            if showMacOSCondition { HStack(spacing: 2) { Image(systemName: "cross.case"); Text("正常") } }
            if showCycles { HStack(spacing: 2) { Image(systemName: "arrow.3.path"); Text("\(viewModel.batteryData.cycleCount ?? 0)") } }
            
            // Specs
            if showTemperature { HStack(spacing: 2) { Image(systemName: "thermometer"); Text(String(format: "%.0f°C", viewModel.temperature)) } }
            if showTimeRemaining { HStack(spacing: 2) { Image(systemName: "clock"); Text("\(viewModel.batteryData.timeRemaining ?? 0)m") } }
            if showAmperage { HStack(spacing: 2) { Image(systemName: "a.square"); Text(String(format: "%.2fA", Double(viewModel.batteryData.amperage) / 1000.0)) } }
            if showVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text(String(format: "%.2fV", Double(viewModel.batteryData.voltage) / 1000.0)) } }
            if showWattage { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text(String(format: "%.1fW", viewModel.batteryData.adapter?.realTimeWatts ?? 0.0)) } }
            if showSystemLoad { HStack(spacing: 2) { Image(systemName: "laptopcomputer"); Text("15.0W") } }
            
            // Adapter
            if showAdapterCurrent { HStack(spacing: 2) { Image(systemName: "powerplug"); Text(String(format: "%.1fA", viewModel.batteryData.adapter?.current ?? 0)) } }
            if showAdapterVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text(String(format: "%.1fV", viewModel.batteryData.adapter?.voltage ?? 0)) } }
            if showAdapterPower { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text(String(format: "%.0fW", viewModel.batteryData.adapter?.watts ?? 0)) } }
            
            // AlDente
            if showAlDenteCalibration { Image(systemName: "slider.vertical.3") }
            if showAlDenteOverheat { Image(systemName: "flame") }
            if showAlDenteSailing { Image(systemName: "paperplane") }
            if showAlDenteFull { Image(systemName: "plus.circle") }
        }
        .font(.system(.body, design: .rounded).monospacedDigit())
        .padding(.horizontal, 2)
    }
}

import SwiftUI

struct BatteryGraphicView: View {
    var capacity: Int
    var isCharging: Bool
    var isPowered: Bool = false  // adapter connected (covers bypass/passthrough)

    @AppStorage(AppPreferenceKeys.iconLowPowerColor) private var iconLowPowerColor = false
    @Environment(\.colorScheme) private var colorScheme

    // Configurable styles
    var isColored: Bool = false
    var chargingStyle: String = "bolt"  // "none", "bolt", "classic", "plug"
    var showNumber: Bool = false
    var isIOSStyle: Bool = false
    var borderStyle: String = "sharp"   // "sharp", "soft"

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
                        if borderStyle == "soft" {
                            // Soft (feathered) knockout border via shadow spread
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .shadow(color: .black, radius: 0.8)
                                .shadow(color: .black, radius: 0.8)
                                .shadow(color: .black, radius: 0.8)
                                .blendMode(.destinationOut)
                                .frame(width: width, alignment: .center)
                        } else {
                            // Sharp knockout border using multi-offset copies (no scaleEffect clipping)
                            let boltKnockout = Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .blendMode(.destinationOut)
                                .frame(width: width, alignment: .center)
                            boltKnockout.offset(x: 0, y: -1)
                            boltKnockout.offset(x: 0, y: 1)
                            boltKnockout.offset(x: -1, y: 0)
                            boltKnockout.offset(x: 1, y: 0)
                            boltKnockout.offset(x: -1, y: -1)
                            boltKnockout.offset(x: -1, y: 1)
                            boltKnockout.offset(x: 1, y: -1)
                            boltKnockout.offset(x: 1, y: 1)
                            boltKnockout
                        }
                        // Solid bolt fill (same color as battery, drawn on top)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(fillColor)
                            .frame(width: width, alignment: .center)
                    case "plug":
                        if borderStyle == "soft" {
                            // Soft (feathered) knockout border via shadow spread
                            Image(systemName: "powerplug.fill")
                                .font(.system(size: 11, weight: .bold))
                                .rotationEffect(.degrees(-90))
                                .offset(x: 4)
                                .foregroundColor(.black)
                                .shadow(color: .black, radius: 0.8)
                                .shadow(color: .black, radius: 0.8)
                                .shadow(color: .black, radius: 0.8)
                                .blendMode(.destinationOut)
                                .frame(width: width, alignment: .center)
                        } else {
                            // Sharp knockout border using multi-offset copies (no scaleEffect clipping)
                            let plugKnockout = Image(systemName: "powerplug.fill")
                                .font(.system(size: 11, weight: .bold))
                                .rotationEffect(.degrees(-90))
                                .offset(x: 4)
                                .foregroundColor(.black)
                                .blendMode(.destinationOut)
                                .frame(width: width, alignment: .center)
                            plugKnockout.offset(x: 0, y: -1)
                            plugKnockout.offset(x: 0, y: 1)
                            plugKnockout.offset(x: -1, y: 0)
                            plugKnockout.offset(x: 1, y: 0)
                            plugKnockout.offset(x: -1, y: -1)
                            plugKnockout.offset(x: -1, y: 1)
                            plugKnockout.offset(x: 1, y: -1)
                            plugKnockout.offset(x: 1, y: 1)
                            plugKnockout
                        }
                        // Solid plug fill (same color as battery, drawn on top)
                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 11, weight: .bold))
                            .rotationEffect(.degrees(-90))
                            .offset(x: 4)
                            .foregroundColor(fillColor)
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
    
    @AppStorage(AppPreferenceKeys.batteryShellStyle) private var batteryShellStyle = "native"
    @AppStorage(AppPreferenceKeys.batteryFillStyle) private var batteryFillStyle = "monochrome"
    @AppStorage(AppPreferenceKeys.batteryInnerContent) private var batteryInnerContent = "none"
    @AppStorage(AppPreferenceKeys.batteryChargingIndicator) private var batteryChargingIndicator = "bolt"
    @AppStorage(AppPreferenceKeys.batteryChargingBorderStyle) private var batteryChargingBorderStyle = "sharp"

    var body: some View {
        Group {
            if !viewModel.batteryData.isAvailable {
                Image(systemName: "battery.0").overlay(Text("?").font(.system(size: 8, weight: .bold)))
            } else if batteryShellStyle != "hidden" {
                BatteryGraphicView(
                    capacity: viewModel.currentCapacity,
                    isCharging: viewModel.isCharging,
                    isPowered: viewModel.powerFlow.hasAdapter,
                    isColored: batteryFillStyle == "status_color",
                    chargingStyle: batteryChargingIndicator,
                    showNumber: batteryInnerContent == "inside",
                    isIOSStyle: batteryShellStyle == "ios",
                    borderStyle: batteryChargingBorderStyle
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
    
    @AppStorage(AppPreferenceKeys.menuBarPowerStyle) private var menuBarPowerStyle: MenuBarPowerStyle = .graphic
    @AppStorage(AppPreferenceKeys.batteryLayout) private var batteryLayout = "left"
    
    @AppStorage(AppPreferenceKeys.showPercentage) private var showPercentage = true
    @AppStorage(AppPreferenceKeys.showChargingStatus) private var showChargingStatus = false
    @AppStorage(AppPreferenceKeys.iconLowPowerColor) private var iconLowPowerColor = false
    @AppStorage(AppPreferenceKeys.batteryInnerContent) private var batteryInnerContent = "none"
    
    @AppStorage(AppPreferenceKeys.showMaxCapacity) private var showMaxCapacity = false
    @AppStorage(AppPreferenceKeys.showMacOSCapacity) private var showMacOSCapacity = false
    @AppStorage(AppPreferenceKeys.showMacOSCondition) private var showMacOSCondition = false
    @AppStorage(AppPreferenceKeys.showCycles) private var showCycles = false
    
    @AppStorage(AppPreferenceKeys.showTemperature) private var showTemperature = false
    @AppStorage(AppPreferenceKeys.showTimeRemaining) private var showTimeRemaining = false
    @AppStorage(AppPreferenceKeys.showAmperage) private var showAmperage = false
    @AppStorage(AppPreferenceKeys.showVoltage) private var showVoltage = false
    @AppStorage(AppPreferenceKeys.showWattage) private var showWattage = false
    @AppStorage(AppPreferenceKeys.showSystemLoad) private var showSystemLoad = false
    
    @AppStorage(AppPreferenceKeys.showAdapterCurrent) private var showAdapterCurrent = false
    @AppStorage(AppPreferenceKeys.showAdapterVoltage) private var showAdapterVoltage = false
    @AppStorage(AppPreferenceKeys.showAdapterPower) private var showAdapterPower = false
    
    @AppStorage(AppPreferenceKeys.showAlDenteCalibration) private var showAlDenteCalibration = false
    @AppStorage(AppPreferenceKeys.showAlDenteOverheat) private var showAlDenteOverheat = false
    @AppStorage(AppPreferenceKeys.showAlDenteSailing) private var showAlDenteSailing = false
    @AppStorage(AppPreferenceKeys.showAlDenteFull) private var showAlDenteFull = false
    
    // Spacing
    @AppStorage(AppPreferenceKeys.menuItemSpacing) private var menuItemSpacing: Double = 4
    @AppStorage(AppPreferenceKeys.mainIconGroupSpacing) private var mainIconGroupSpacing: Double = 4

    // Battery Man
    @AppStorage(AppPreferenceKeys.batteryManLegLength) private var batteryManLegLength: BatteryManLegLength = .normal
    @AppStorage(AppPreferenceKeys.batteryManShowFace) private var batteryManShowFace = false
    @AppStorage(AppPreferenceKeys.batteryManShowArms) private var batteryManShowArms = false
    @AppStorage(AppPreferenceKeys.batteryManShowPosture) private var batteryManShowPosture = false
    @AppStorage(AppPreferenceKeys.batteryManShowAccessory) private var batteryManShowAccessory = false
    @AppStorage(AppPreferenceKeys.batteryManFaceStyle) private var batteryManFaceStyle: BatteryManFaceStyle = .solid
    @AppStorage(AppPreferenceKeys.batteryManHandAction) private var batteryManHandAction = "none"
    @AppStorage(AppPreferenceKeys.batteryManHandActionSide) private var batteryManHandActionSide = "right"

    var body: some View {
        HStack(spacing: CGFloat(menuItemSpacing)) {
            // Main Icon Group
            HStack(spacing: CGFloat(mainIconGroupSpacing)) {
                if menuBarPowerStyle == .graphic {
                    if batteryLayout == "left", let image = generatedMenuImage { Image(nsImage: image) }

                    if batteryInnerContent == "outside" { Text(viewModel.capacityText) }
                    if showChargingStatus && viewModel.isCharging { Image(systemName: "bolt.fill") }

                    if batteryLayout == "right", let image = generatedMenuImage { Image(nsImage: image) }
                } else if menuBarPowerStyle == .batteryMan {
                    if batteryLayout == "left" {
                        BatteryManView(
                            capacity: viewModel.currentCapacity,
                            isCharging: viewModel.isCharging,
                            isPowered: viewModel.powerFlow.hasAdapter,
                            isColored: false,
                            showBolt: true,
                            legLength: batteryManLegLength,
                            showFace: batteryManShowFace,
                            showArms: batteryManShowArms,
                            showPosture: batteryManShowPosture,
                            showAccessory: batteryManShowAccessory,
                            faceStyle: batteryManFaceStyle,
                            handAction: batteryManHandAction,
                            handActionSide: batteryManHandActionSide
                        )
                    }
                    if showPercentage { Text(viewModel.capacityText) }
                    if showChargingStatus && viewModel.isCharging { Image(systemName: "bolt.fill") }
                    if batteryLayout == "right" {
                        BatteryManView(
                            capacity: viewModel.currentCapacity,
                            isCharging: viewModel.isCharging,
                            isPowered: viewModel.powerFlow.hasAdapter,
                            isColored: false,
                            showBolt: true,
                            legLength: batteryManLegLength,
                            showFace: batteryManShowFace,
                            showArms: batteryManShowArms,
                            showPosture: batteryManShowPosture,
                            showAccessory: batteryManShowAccessory,
                            faceStyle: batteryManFaceStyle,
                            handAction: batteryManHandAction,
                            handActionSide: batteryManHandActionSide
                        )
                    }
                } else if menuBarPowerStyle == .symbolic {
                    Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")
                        .symbolRenderingMode(.hierarchical)
                    if showPercentage { Text(viewModel.capacityText) }
                } else if menuBarPowerStyle == .textOnly {
                    Text(viewModel.capacityText)
                        .fontWeight(.bold)
                }
            }
            
            // Health
            if showMaxCapacity { HStack(spacing: 2) { Image(systemName: "stethoscope"); Text(viewModel.batteryData.healthPercent.map { "H:\($0)%" } ?? "H:—") } }
            if showMacOSCapacity { HStack(spacing: 2) { Image(systemName: "info.circle"); Text(viewModel.batteryData.appleMaxCapacity.map { "S:\($0)%" } ?? "S:—") } }
            if showMacOSCondition { HStack(spacing: 2) { Image(systemName: "cross.case"); Text(viewModel.batteryData.condition ?? "—") } }
            if showCycles { HStack(spacing: 2) { Image(systemName: "arrow.3.path"); Text(viewModel.batteryData.isAvailable ? "\(viewModel.batteryData.cycleCount)" : "—") } }
            
            // Specs
            if showTemperature { HStack(spacing: 2) { Image(systemName: "thermometer"); Text(viewModel.temperature > 0 ? String(format: "%.0f°C", viewModel.temperature) : "—") } }
            if showTimeRemaining { HStack(spacing: 2) { Image(systemName: "clock"); Text(viewModel.batteryData.timeRemaining.map { "\($0)m" } ?? "—") } }
            if showAmperage { HStack(spacing: 2) { Image(systemName: "a.square"); Text(viewModel.batteryData.hasCurrentReading ? String(format: "%.2fA", Double(viewModel.batteryData.amperage) / 1000.0) : "—") } }
            if showVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text(viewModel.voltage > 0 ? String(format: "%.2fV", Double(viewModel.voltage) / 1000.0) : "—") } }
            if showWattage { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text(viewModel.powerFlow.adapterQuality.format(viewModel.powerFlow.adapterPower)) } }
            if showSystemLoad { HStack(spacing: 2) { Image(systemName: "laptopcomputer"); Text(viewModel.powerFlow.systemQuality.format(viewModel.powerFlow.systemPower)) } }
            
            // Adapter
            if showAdapterCurrent { HStack(spacing: 2) { Image(systemName: "powerplug"); Text(viewModel.powerFlow.adapterCurrent.map { String(format: "%.1fA", $0) } ?? "—") } }
            if showAdapterVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text(viewModel.powerFlow.adapterVoltage.map { String(format: "%.1fV", $0) } ?? "—") } }
            if showAdapterPower { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text(viewModel.powerFlow.adapterQuality.format(viewModel.powerFlow.adapterPower)) } }
            

        }
        .font(.system(.body, design: .rounded).monospacedDigit())
        .padding(.horizontal, 2)
    }
}

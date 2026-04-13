import SwiftUI

struct BatteryGraphicView: View {
    @ObservedObject var viewModel: StatusViewModel
    
    // Config
    var width: CGFloat = 40
    var height: CGFloat = 18
    
    var body: some View {
        let percentage = Double(viewModel.currentCapacity) / 100.0
        let fillWidth = max(0, (width - 4) * percentage)
        let isCritical = viewModel.currentCapacity <= 20
        let fillColor: Color = viewModel.isCharging ? .green : (isCritical ? .red : .primary)
        
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                // Outer Shell
                RoundedRectangle(cornerRadius: 3.5)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    .frame(width: width, height: height)
                
                // Fill
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(fillColor)
                    .frame(width: fillWidth, height: height - 4)
                    .padding(.leading, 2)
                
                // Text and Icon inside
                HStack(spacing: 2) {
                    Text("\(viewModel.currentCapacity)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(percentage > 0.5 || viewModel.isCharging ? .white : .primary)
                    
                    if viewModel.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(percentage > 0.5 || viewModel.isCharging ? .white : .primary)
                    }
                }
                .frame(width: width, alignment: .center)
            }
            
            // Battery Tip
            Path { path in
                path.move(to: CGPoint(x: 0, y: height * 0.25))
                path.addLine(to: CGPoint(x: 1.5, y: height * 0.25))
                path.addQuadCurve(to: CGPoint(x: 1.5, y: height * 0.75), control: CGPoint(x: 2.5, y: height * 0.5))
                path.addLine(to: CGPoint(x: 0, y: height * 0.75))
                path.closeSubpath()
            }
            .fill(Color.primary.opacity(0.3))
            .frame(width: 2.5, height: height)
        }
    }
}

// A view that combines the battery graphic with other items for the Menu Bar
struct MenuBarLabelRendererView: View {
    @ObservedObject var viewModel: StatusViewModel
    
    @AppStorage("menuBarIconStyle") private var menuBarIconStyle = "battery"
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = false
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    
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
    
    @AppStorage("menuItemSpacing") private var menuItemSpacing: Double = 4

    var body: some View {
        HStack(spacing: menuItemSpacing) {
            // Main Icon
            if menuBarIconStyle != "none" {
                if menuBarIconStyle == "battery" { 
                    BatteryGraphicView(viewModel: viewModel) // Custom battery drawing
                }
                else if menuBarIconStyle == "ios_native" { Image(systemName: "battery.75") }
                else if menuBarIconStyle == "macos_color" { Image(systemName: "battery.100").foregroundColor(.green) }
                else if menuBarIconStyle == "aldente_status" { Image(systemName: "minus.plus.batteryblock.fill") }
                else if menuBarIconStyle == "aldente_icon" { Image(systemName: "leaf") }
                else { Image(systemName: "battery.100") }
            }
            
            if showPercentage { Text("\(viewModel.currentCapacity)%") }
            if showChargingStatus && viewModel.isCharging { Image(systemName: "bolt.fill") }
            if iconLowPowerColor && viewModel.currentCapacity <= 20 { Circle().fill(Color.orange).frame(width: 8, height: 8) }
            
            // Health
            if showMaxCapacity { HStack(spacing: 2) { Image(systemName: "stethoscope"); Text("\(viewModel.batteryData.appleRawMaxCapacity ?? 0)%") } }
            if showMacOSCapacity { HStack(spacing: 2) { Image(systemName: "info.circle"); Text("\(viewModel.batteryData.appleMaxCapacity ?? 0)%") } }
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
        .padding(2)
        .fixedSize() // Let it determine its own size
    }
}

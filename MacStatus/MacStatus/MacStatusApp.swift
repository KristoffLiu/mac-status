import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @StateObject private var viewModel = StatusViewModel()

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    
    @State private var settingsUpdateTrigger = UUID()

    var body: some Scene {
        // Dummy hidden MenuBarExtra scene to intercept SwiftUI's default start-up window behavior.
        // SwiftUI won't automatically open the secondary 'Window' scene on app launch,
        // and since `isInserted` is false, this MenuBarExtra won't show an icon either.
        MenuBarExtra("Hidden", systemImage: "star", isInserted: .constant(false)) {
            EmptyView()
        }
        
        MenuBarExtra {
            MainPanelView(viewModel: viewModel)
        } label: {
            MenuBarLabelView(viewModel: viewModel)
                .id(settingsUpdateTrigger)
        }
        .menuBarExtraStyle(.window) // This gives the native popover with the 'tip' pointing to the menu bar!
        
        Window("MacStatus", id: "settings") {
            MainWindowView()
                .onChange(of: viewModel.isCharging) { _ in settingsUpdateTrigger = UUID() }
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                    settingsUpdateTrigger = UUID()
                }
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}

struct MenuBarLabelView: View {
    @ObservedObject var viewModel: StatusViewModel
    
    // Status Bar Configuration
    @AppStorage("menuBarIconStyle") private var menuBarIconStyle = "battery"
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = false
    @AppStorage("showCycles") private var showCycles = false
    @AppStorage("showTemperature") private var showTemperature = false
    @AppStorage("showWattage") private var showWattage = false
    @AppStorage("showVoltage") private var showVoltage = false
    @AppStorage("showAmperage") private var showAmperage = false
    @AppStorage("menuItemSpacing") private var menuItemSpacing: Double = 4

    // 主图标选项
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = false
    
    // 电池健康
    @AppStorage("showMaxCapacity") private var showMaxCapacity = false
    @AppStorage("showMacOSCapacity") private var showMacOSCapacity = false
    @AppStorage("showMacOSCondition") private var showMacOSCondition = false
    
    // 电池规格
    @AppStorage("showTimeRemaining") private var showTimeRemaining = false
    @AppStorage("showSystemLoad") private var showSystemLoad = false
    
    // 电源适配器规格
    @AppStorage("showAdapterCurrent") private var showAdapterCurrent = false
    @AppStorage("showAdapterVoltage") private var showAdapterVoltage = false
    @AppStorage("showAdapterPower") private var showAdapterPower = false
    
    // AlDente 状态
    @AppStorage("showAlDenteCalibration") private var showAlDenteCalibration = false
    @AppStorage("showAlDenteOverheat") private var showAlDenteOverheat = false
    @AppStorage("showAlDenteSailing") private var showAlDenteSailing = false
    @AppStorage("showAlDenteFull") private var showAlDenteFull = false
    
    var body: some View {
        var str = Text("")
        let space = Text(String(repeating: " ", count: max(1, Int(menuItemSpacing) / 3)))
        
        if menuBarIconStyle != "none" {
            if menuBarIconStyle == "battery" { str = str + Text(Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")) + space }
            else if menuBarIconStyle == "ios_native" { str = str + Text(Image(systemName: "battery.75")) + space }
            else if menuBarIconStyle == "macos_color" { str = str + Text(Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")).foregroundColor(.green) + space }
            else if menuBarIconStyle == "aldente_status" { str = str + Text(Image(systemName: "minus.plus.batteryblock.fill")) + space }
            else if menuBarIconStyle == "aldente_icon" { str = str + Text(Image(systemName: "leaf")) + space }
            else { str = str + Text(Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100")) + space }
        }
        
        if showPercentage { str = str + Text("\(viewModel.currentCapacity)%") + space }
        if showChargingStatus { str = str + Text(Image(systemName: viewModel.isCharging ? "bolt.fill" : "bolt.slash.fill")) + space }
        if iconLowPowerColor { str = str + Text(Image(systemName: "circle.fill")).foregroundColor(.orange) + space }
        
        if showMaxCapacity { str = str + Text(Image(systemName: "stethoscope")) + Text(" \(viewModel.batteryData.maxCapacity)") + space }
        if showMacOSCapacity { str = str + Text(Image(systemName: "info.circle")) + Text(" \(viewModel.currentCapacity)%") + space }
        if showMacOSCondition { str = str + Text(Image(systemName: "cross.case")) + Text(" 正常") + space }
        if showCycles { str = str + Text(Image(systemName: "arrow.3.path")) + Text(" \(viewModel.cycleCount)") + space }
        
        if showTemperature { str = str + Text(Image(systemName: "thermometer")) + Text(String(format: " %.0f°C", viewModel.temperature)) + space }
        if showTimeRemaining { str = str + Text(Image(systemName: "clock")) + Text(" 2:30") + space }
        if showAmperage { str = str + Text(Image(systemName: "a.square")) + Text(String(format: " %.1fA", Double(abs(viewModel.amperage)) / 1000.0)) + space }
        if showVoltage { str = str + Text(Image(systemName: "v.square")) + Text(String(format: " %.1fV", Double(viewModel.voltage) / 1000.0)) + space }
        if showWattage { str = str + Text(Image(systemName: "bolt.fill")) + Text(String(format: " %.1fW", viewModel.batteryData.adapter?.realTimeWatts ?? 0.0)) + space }
        if showSystemLoad { str = str + Text(Image(systemName: "laptopcomputer")) + Text(String(format: " %.1fW", abs(Double(viewModel.voltage) * Double(viewModel.amperage) / 1_000_000.0))) + space }
        
        if showAdapterCurrent { str = str + Text(Image(systemName: "powerplug")) + Text(String(format: " %.1fA", viewModel.batteryData.adapter?.activeProfile?.maxCurrent ?? 0.0)) + space }
        if showAdapterVoltage { str = str + Text(Image(systemName: "v.square")) + Text(String(format: " %.1fV", viewModel.batteryData.adapter?.activeProfile?.maxVoltage ?? 0.0)) + space }
        if showAdapterPower { str = str + Text(Image(systemName: "bolt.fill")) + Text(String(format: " %.0fW", viewModel.batteryData.adapterWatts)) + space }
        
        if showAlDenteCalibration { str = str + Text(Image(systemName: "slider.vertical.3")) + space }
        if showAlDenteOverheat { str = str + Text(Image(systemName: "flame")) + space }
        if showAlDenteSailing { str = str + Text(Image(systemName: "paperplane")) + space }
        if showAlDenteFull { str = str + Text(Image(systemName: "plus.circle")) + space }
        
        return str.font(.system(.body, design: .rounded).monospacedDigit())
    }

}

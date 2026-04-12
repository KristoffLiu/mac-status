import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @StateObject private var viewModel = StatusViewModel()

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

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
        }
        .menuBarExtraStyle(.window) // This gives the native popover with the 'tip' pointing to the menu bar!
        
        // Main Application Window with Sidebar
        Window("MacStatus", id: "settings") {
            MainWindowView()
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
        HStack(spacing: menuItemSpacing) {
            
            if menuBarIconStyle != "none" {
                if menuBarIconStyle == "battery" { 
                    Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100") 
                }
                else if menuBarIconStyle == "ios_native" { 
                    Image(systemName: "battery.75") 
                }
                else if menuBarIconStyle == "macos_color" { 
                    Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100").foregroundColor(.green) 
                }
                else if menuBarIconStyle == "aldente_status" { 
                    Image(systemName: "minus.plus.batteryblock.fill") 
                }
                else if menuBarIconStyle == "aldente_icon" { 
                    Image(systemName: "leaf") 
                }
                else { 
                    Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.100") 
                }
            }
            
            if showPercentage {
                Text("\(viewModel.currentCapacity)%")
            }
            
            if showChargingStatus {
                Image(systemName: viewModel.isCharging ? "bolt.fill" : "bolt.slash.fill")
            }
            
            if iconLowPowerColor {
                Circle().fill(Color.orange).frame(width: 8, height: 8)
            }
            
            // Battery Health
            if showMaxCapacity { HStack(spacing: 2) { Image(systemName: "stethoscope"); Text("\(viewModel.batteryData.maxCapacity)") } }
            if showMacOSCapacity { HStack(spacing: 2) { Image(systemName: "info.circle"); Text("\(viewModel.currentCapacity)%") } }
            if showMacOSCondition { HStack(spacing: 2) { Image(systemName: "cross.case"); Text("正常") } }
            if showCycles {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.3.path").font(.caption)
                    Text("\(viewModel.cycleCount)")
                }
            }
            
            // Battery Specs
            if showTemperature {
                HStack(spacing: 2) {
                    Image(systemName: "thermometer")
                    Text(String(format: "%.0f°C", viewModel.temperature))
                }
            }
            if showTimeRemaining { HStack(spacing: 2) { Image(systemName: "clock"); Text("2:30") } }
            if showAmperage {
                HStack(spacing: 2) {
                    Image(systemName: "a.square")
                    Text(String(format: "%.1fA", Double(abs(viewModel.amperage)) / 1000.0))
                }
            }
            if showVoltage {
                HStack(spacing: 2) {
                    Image(systemName: "v.square")
                    Text(String(format: "%.1fV", Double(viewModel.voltage) / 1000.0))
                }
            }
            if showWattage {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                    Text(String(format: "%.1fW", abs(viewModel.powerFlow.systemPower)))
                }
            }
            if showSystemLoad { HStack(spacing: 2) { Image(systemName: "laptopcomputer"); Text("15.0W") } }
            
            // Adapter Specs
            if showAdapterCurrent { HStack(spacing: 2) { Image(systemName: "powerplug"); Text(String(format: "%.1fA", viewModel.batteryData.adapter?.activeProfile?.maxCurrent ?? 0)) } }
            if showAdapterVoltage { HStack(spacing: 2) { Image(systemName: "v.square"); Text(String(format: "%.1fV", viewModel.batteryData.adapter?.activeProfile?.maxVoltage ?? 0)) } }
            if showAdapterPower { HStack(spacing: 2) { Image(systemName: "bolt.fill"); Text(String(format: "%dW", Int(viewModel.batteryData.adapterWatts))) } }
            
            // AlDente State
            if showAlDenteCalibration { Image(systemName: "slider.vertical.3") }
            if showAlDenteOverheat { Image(systemName: "flame") }
            if showAlDenteSailing { Image(systemName: "paperplane") }
            if showAlDenteFull { Image(systemName: "plus.circle") }
        }
        .font(.system(.body, design: .rounded).monospacedDigit())
    }
}

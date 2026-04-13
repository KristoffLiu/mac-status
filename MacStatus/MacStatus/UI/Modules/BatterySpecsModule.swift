import SwiftUI

struct BatterySpecsModule: View {
    var batteryData: BatteryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("电池规格")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            HStack {
                let volts = Double(batteryData.voltage) / 1000.0
                detailItem(title: "电芯输出电压", value: String(format: "%.2f V", volts))
                Spacer()
                let amps = Double(batteryData.amperage) / 1000.0
                detailItem(title: "电芯输出电流", value: String(format: "%.2f A", abs(amps)))
            }
            
            HStack {
                let volts = Double(batteryData.voltage) / 1000.0
                let amps = Double(batteryData.amperage) / 1000.0
                let batteryWatts = abs(volts * amps)
                detailItem(title: "电芯供流负载", value: String(format: "%.2f W", batteryWatts))
                Spacer()
                detailItem(title: "内部温度", value: String(format: "%.1f°C", batteryData.temperature))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
    
    private func detailItem(title: String, value: String, width: CGFloat = 140) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: width, alignment: .leading)
    }
}

// MARK: - Plugin Definition
struct BatterySpecsPlugin: AppWidgetPlugin {
    let id = "batterySpecs"
    let name = "电池规格"
    let icon = "battery.100.bolt"
    let hasSettings = false
    
    @MainActor
    var contentView: AnyView {
        AnyView(BatterySpecsPluginContentView())
    }
    
    @MainActor
    var settingsView: AnyView {
        AnyView(EmptyView())
    }
}

private struct BatterySpecsPluginContentView: View {
    @EnvironmentObject var viewModel: StatusViewModel
    
    var body: some View {
        BatterySpecsModule(batteryData: viewModel.batteryData)
    }
}


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
    
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("showChargingStatus") private var showChargingStatus = true
    @AppStorage("iconLowPowerColor") private var iconLowPowerColor = true
    
    @AppStorage("showTemperature") private var showTemperature = false
    @AppStorage("showWattage") private var showWattage = false
    
    // We can use an HStack now, because this entire view will be rendered to a single NSImage!
    var body: some View {
        HStack(spacing: 6) {
            // Highly Custom Battery Graphic
            BatteryGraphicView(viewModel: viewModel)
            
            // Other elements
            if showTemperature {
                HStack(spacing: 2) {
                    Image(systemName: "thermometer")
                    Text(String(format: "%.0f°C", viewModel.temperature))
                }
            }
            if showWattage {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                    Text(String(format: "%.1fW", viewModel.batteryData.adapter?.realTimeWatts ?? 0.0))
                }
            }
        }
        .font(.system(.body, design: .rounded).monospacedDigit())
        .padding(2)
        .fixedSize() // Let it determine its own size
    }
}

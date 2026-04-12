import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StatusViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("MacStatus")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: viewModel.isCharging ? "bolt.fill" : "battery.100")
                    .foregroundColor(viewModel.isCharging ? .green : .primary)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Primary Status: Wattage
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Power")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", viewModel.wattage))
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                        Text("W")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    if viewModel.adapterWatts > 0 && viewModel.wattage == 0 {
                        Text("Adapter limit: \(viewModel.adapterWatts) W")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(viewModel.powerDirection)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                    
                    Text("\(viewModel.amperage) mA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Text("\(viewModel.voltage) mV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                }
            }
            
            Divider()
            
            // Battery details grid
            VStack(spacing: 12) {
                HStack {
                    detailView(title: "Capacity", value: "\(viewModel.currentCapacity)%")
                    Spacer()
                    detailView(title: "Health", value: "\(calculateHealth())%")
                }
                HStack {
                    detailView(title: "Cycles", value: "\(viewModel.cycleCount)")
                    Spacer()
                    detailView(title: "Temperature", value: String(format: "%.1f°C", viewModel.temperature))
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding()
        .frame(width: 260)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var statusColor: Color {
        if viewModel.amperage > 0 { return .green }
        if viewModel.amperage < 0 { return .orange }
        return .blue
    }
    
    // AlDente style detail block
    private func detailView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(width: 100, alignment: .leading)
    }
    
    private func calculateHealth() -> Int {
        guard viewModel.designCapacity > 0 else { return 100 }
        let health = Double(viewModel.maxCapacity) / Double(viewModel.designCapacity) * 100
        return Int(min(100.0, health))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

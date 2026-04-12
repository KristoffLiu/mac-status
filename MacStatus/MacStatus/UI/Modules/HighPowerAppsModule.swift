import SwiftUI

struct HighPowerAppsModule: View {
    @ObservedObject var service = HighPowerAppsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if service.highPowerApps.isEmpty {
                HStack {
                    Text("No Applications Using Significant Energy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            } else {
                Text("High Power:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
                
                ForEach(service.highPowerApps) { app in
                    HStack {
                        // Truncate long names to keep UI clean
                        Text(app.name)
                            .font(.system(.subheadline, design: .rounded))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", app.power))
                            .font(.system(.subheadline, design: .rounded).monospacedDigit())
                            .fontWeight(.medium)
                            .foregroundColor(powerColor(for: app.power))
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
    
    private func powerColor(for power: Double) -> Color {
        if power > 50 { return .red }
        if power > 20 { return .orange }
        return .primary
    }
}

struct HighPowerAppsModule_Previews: PreviewProvider {
    static var previews: some View {
        HighPowerAppsModule()
            .frame(width: 300)
            .padding()
            .background(Color.black.opacity(0.8))
    }
}

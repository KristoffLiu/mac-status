import SwiftUI

struct BlockPowerFlowView: View {
    var powerFlow: PowerFlowData
    
    var body: some View {
        HStack(spacing: 8) {
            // Source Side
            VStack(spacing: 8) {
                if powerFlow.adapterPower > 0 {
                    BlockNode(icon: "powerplug.fill", title: "电源适配器", value: powerFlow.adapterPower, color: .yellow)
                }
                if powerFlow.directionalBatteryPower > 0 && powerFlow.topology == .topologyB {
                    BlockNode(icon: "battery.100", title: "电池输出", value: powerFlow.directionalBatteryPower, color: .blue)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.system(size: 20, weight: .bold))
            
            // Sink Side
            VStack(spacing: 8) {
                BlockNode(icon: "laptopcomputer", title: "系统消耗", value: powerFlow.systemPower, color: .primary)
                
                if powerFlow.directionalBatteryPower > 0 && powerFlow.topology == .topologyA {
                    BlockNode(icon: "battery.100.bolt", title: "电池充入", value: powerFlow.directionalBatteryPower, color: .green)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

fileprivate struct BlockNode: View {
    var icon: String
    var title: String
    var value: Double
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                let textValue = (value == -1.0) ? "-- W" : String(format: "%.1f W", value)
                Text(textValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

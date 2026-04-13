import SwiftUI
import Combine

struct DashboardView: View {
    @State private var batteryData = BatteryData.empty
    
    // Simulate real-time updates for now
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Content: 2-Column Layout
                HStack(alignment: .top, spacing: 20) {
                    
                    // Left Column
                    VStack(spacing: 20) {
                        // 电池规格 Card
                        DashboardCard(title: "电池规格", icon: "bolt.fill", iconColor: .blue) {
                            VStack(spacing: 12) {
                                DataRow(label: "Current", value: String(format: "%.2f A", Double(batteryData.amperage) / 1000.0))
                                DataRow(label: "Voltage", value: String(format: "%.2f V", Double(batteryData.voltage) / 1000.0))
                                DataRow(label: "Power", value: String(format: "%.2f W", batteryData.adapter?.realTimeWatts ?? 0.0))
                                DataRow(label: "System Load", value: String(format: "%.2f W", abs(Double(batteryData.voltage) * Double(batteryData.amperage) / 1_000_000.0)))
                                DataRow(label: "Remaining Capacity", value: "\(batteryData.currentCapacity) mAh")
                            }
                        }
                        
                        // 电源适配器规格 Card
                        DashboardCard(title: "电源适配器规格", icon: "powerplug.fill", iconColor: .teal) {
                            VStack(spacing: 12) {
                                let maxC = batteryData.adapter?.activeProfile?.maxCurrent ?? 0
                                let maxV = batteryData.adapter?.activeProfile?.maxVoltage ?? 0
                                DataRow(label: "Adapter Name", value: batteryData.adapter?.name ?? "Unknown")
                                DataRow(label: "Design Power", value: "\(batteryData.adapterWatts) W")
                                DataRow(label: "Negotiated Current", value: String(format: "%.2f A", maxC))
                                DataRow(label: "Negotiated Voltage", value: String(format: "%.2f V", maxV))
                            }
                        }
                    }
                    
                    // Right Column
                    VStack(spacing: 20) {
                        // 电池健康 Card
                        DashboardCard(title: "电池健康", icon: "heart.fill", iconColor: .red) {
                            VStack(spacing: 12) {
                                DataRow(label: "Design Capacity", value: "\(batteryData.designCapacity) mAh")
                                DataRow(label: "Maximum Capacity", value: "\(batteryData.maxCapacity) mAh")
                                let healthPercent = batteryData.designCapacity > 0 ? (Double(batteryData.maxCapacity) / Double(batteryData.designCapacity)) * 100 : 0
                                DataRow(label: "macOS Status", value: healthPercent > 80 ? "Normal" : "Service Recommended")
                                DataRow(label: "Cycle Count", value: "\(batteryData.cycleCount)")
                            }
                        }
                    }
                }
                
                // Bottom Row: Small metrics widgets
                HStack(spacing: 20) {
                    DashboardSimpleCard(
                        title: "Battery Level", 
                        value: "\(batteryData.maxCapacity > 0 ? Int((Double(batteryData.currentCapacity) / Double(batteryData.maxCapacity)) * 100) : 0) %", 
                        icon: batteryData.maxCapacity > 0 ? "battery.100" : "battery.0",
                        iconColor: .green
                    )
                    DashboardSimpleCard(
                        title: "Battery Temperature", 
                        value: batteryData.temperature > 0 ? String(format: "%.1f°C", batteryData.temperature) : "--", 
                        icon: "thermometer",
                        iconColor: .orange
                    )
                    DashboardSimpleCard(
                        title: "Charging State", 
                        value: batteryData.isCharging ? "Charging" : "Discharging", 
                        icon: batteryData.isCharging ? "bolt.fill" : "battery.25",
                        iconColor: batteryData.isCharging ? .yellow : .blue
                    )
                }
            }
            .padding(32)
        }
        .navigationTitle("仪表盘")
        // In macOS 14+, using clear background with control opacity replicates the typical System Settings feel
        .background(VisualEffectBackground(material: .contentBackground, blendingMode: .withinWindow))
        .onAppear {
            self.batteryData = BatteryService.shared.fetchBatteryData()
        }
        .onReceive(timer) { _ in
            self.batteryData = BatteryService.shared.fetchBatteryData()
        }
    }
}

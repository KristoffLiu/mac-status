import Foundation

/// Geometry for adapter/battery sources converging on the system node.
nonisolated struct SankeySupplyLayout {
    let adapterHeight: CGFloat
    let batteryHeight: CGFloat
    let sourceHeight: CGFloat
    let systemHeight: CGFloat
    let adapterPortHeight: CGFloat
    let batteryPortHeight: CGFloat
    let gap: CGFloat

    init(adapterPower: Double, batteryPower: Double, sinksHeight: CGFloat = 0) {
        let total = max(adapterPower + batteryPower, 0.1)
        let base = 64.0 + pow(min(total, 140.0) / 140.0, 0.6) * 56.0
        let hasAdapter = adapterPower > 0
        let hasBattery = batteryPower > 0
        let isHybrid = hasAdapter && hasBattery
        // Share a compact height budget instead of adding independently clamped nodes.
        let flowHeight = max(isHybrid ? 112.0 : 70.0, base)
        if isHybrid {
            adapterHeight = min(max(flowHeight * adapterPower / total, 48), flowHeight - 48)
            batteryHeight = flowHeight - adapterHeight
        } else {
            adapterHeight = hasAdapter ? flowHeight : 0
            batteryHeight = hasBattery ? flowHeight : 0
        }
        gap = isHybrid ? 12 : 0
        sourceHeight = max(70, adapterHeight + batteryHeight + gap)
        systemHeight = max(flowHeight, sinksHeight)
        // Minimum visual widths keep small contributions legible; watt labels stay exact.
        if isHybrid {
            adapterPortHeight = min(max(systemHeight * adapterPower / total, 24), systemHeight - 24)
            batteryPortHeight = systemHeight - adapterPortHeight
        } else {
            adapterPortHeight = hasAdapter ? systemHeight : 0
            batteryPortHeight = hasBattery ? systemHeight : 0
        }
    }
}

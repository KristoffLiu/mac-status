import Foundation

nonisolated struct SamplingPolicy: Equatable, Sendable {
    var panelVisible = false
    var sleeping = false
    var widgets: Set<String> = []
    var threeStage = false
    var flowStyle = "cards"
    var activeInterval: Double = 1
    var backgroundInterval: Double = 10

    var tickInterval: Double? { sleeping ? nil : (panelVisible ? Self.clampInterval(activeInterval) : Self.clampBackgroundInterval(backgroundInterval)) }
    var needsBreakdown: Bool {
        panelVisible && !sleeping && widgets.contains("powerFlow") && threeStage && ["sankey", "cards"].contains(flowStyle)
    }
    var needsSystemMetrics: Bool { panelVisible && !sleeping && (widgets.contains("systemMonitor") || needsBreakdown) }
    var needsHighPowerApps: Bool { panelVisible && !sleeping && widgets.contains("highPowerApps") }
    var appInterval: Double { max(2, Self.clampInterval(activeInterval) * 2) }

    static func clampBackgroundInterval(_ value: Double) -> Double {
        value.isFinite && value >= 2 && value <= 20 ? value : 10
    }

    static func clampInterval(_ value: Double) -> Double {
        value.isFinite && value >= 0.2 && value <= 2 ? value : 1
    }
}

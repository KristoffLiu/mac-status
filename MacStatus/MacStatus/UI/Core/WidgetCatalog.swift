import SwiftUI

enum WidgetID: String, CaseIterable, Identifiable {
    case powerFlow
    case batterySpecs
    case batteryHealth
    case highPowerApps
    case systemMonitor

    var id: String { rawValue }

    var name: String {
        switch self {
        case .powerFlow: "实时能耗流"
        case .batterySpecs: "电池规格"
        case .batteryHealth: "电池健康"
        case .highPowerApps: "高耗能应用"
        case .systemMonitor: "系统监控"
        }
    }

    var icon: String {
        switch self {
        case .powerFlow: "bolt.horizontal"
        case .batterySpecs: "battery.100.bolt"
        case .batteryHealth: "heart.fill"
        case .highPowerApps: "cpu"
        case .systemMonitor: "chart.xyaxis.line"
        }
    }

    var iconColor: Color {
        switch self {
        case .powerFlow: .green
        case .batterySpecs: .blue
        case .batteryHealth: .red
        case .highPowerApps: .orange
        case .systemMonitor: .purple
        }
    }

    var hasSettings: Bool {
        self == .powerFlow || self == .systemMonitor
    }

    func wantsEdgeToEdge(powerFlowStyle: PowerFlowStyle) -> Bool {
        self == .powerFlow && powerFlowStyle == .cards
    }

    @MainActor @ViewBuilder
    func content(viewModel: StatusViewModel) -> some View {
        switch self {
        case .powerFlow:
            PowerFlowModuleView(powerFlow: viewModel.powerFlow, batteryData: viewModel.batteryData)
        case .batterySpecs:
            BatterySpecsModule(batteryData: viewModel.batteryData)
        case .batteryHealth:
            BatteryHealthModule(batteryData: viewModel.batteryData)
        case .highPowerApps:
            HighPowerAppsModule()
        case .systemMonitor:
            SystemMonitorModule()
        }
    }

    @MainActor @ViewBuilder
    var settings: some View {
        switch self {
        case .powerFlow:
            PowerFlowConfigView()
        case .systemMonitor:
            SystemMonitorConfigView()
        case .batterySpecs, .batteryHealth, .highPowerApps:
            EmptyView()
        }
    }
}

enum WidgetCatalog {
    static let defaultOrder = AppPreferences.defaultWidgetOrder

    static var allIDs: [String] { WidgetID.allCases.map(\.rawValue) }

    static func sanitize(_ stored: [String]) -> [String] {
        var seen = Set<String>()
        return stored.filter { WidgetID(rawValue: $0) != nil && seen.insert($0).inserted }
    }
}

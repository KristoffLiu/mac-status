import Foundation

enum MenuBarPowerStyle: String, CaseIterable, Identifiable {
    case graphic = "graphic"       // 电池
    case batteryMan = "batteryMan" // 电池人（占位）
    case symbolic = "symbolic"     // 简约图标 (Simple icon) — 保留兼容
    case textOnly = "textOnly"     // 纯电量数字 (Pure data) — 保留兼容

    var id: String { rawValue }

    var title: String {
        switch self {
        case .graphic: return "电池"
        case .batteryMan: return "电池人"
        case .symbolic: return "简约图标"
        case .textOnly: return "纯电量数字"
        }
    }

    var icon: String {
        switch self {
        case .graphic: return "battery.100"
        case .batteryMan: return "figure.walk"
        case .symbolic: return "battery.50"
        case .textOnly: return "number.square"
        }
    }
}

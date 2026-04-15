import Foundation

enum MenuBarPowerStyle: String, CaseIterable, Identifiable {
    case graphic = "graphic"     // 图色外观 (The high-fidelity icon)
    case symbolic = "symbolic"   // 简约图标 (Simple icon)
    case textOnly = "textOnly"   // 纯电量数字 (Pure data)
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .graphic: return "图形外观"
        case .symbolic: return "简约图标"
        case .textOnly: return "纯电量数字"
        }
    }
    
    var icon: String {
        switch self {
        case .graphic: return "battery.100"
        case .symbolic: return "battery.50"
        case .textOnly: return "number.square"
        }
    }
}

import SwiftUI

protocol AppWidgetPlugin {
    var id: String { get }
    var name: String { get } // Human-readable fallback/drawer name
    var icon: String { get }
    
    // Whether this plugin has settings
    var hasSettings: Bool { get }
    
    // Extracted content
    @MainActor var contentView: AnyView { get }
    @MainActor var settingsView: AnyView { get }
    
    // Whether this plugin should natively bleed edge-to-edge horizontally
    var wantsEdgeToEdge: Bool { get }
}

extension AppWidgetPlugin {
    var wantsEdgeToEdge: Bool { return false }
    
    var iconColor: Color {
        switch self.id {
        case "powerFlow": return .green
        case "batterySpecs": return .blue
        case "batteryHealth": return .red
        case "highPowerApps": return .orange
        case "systemMonitor": return .purple
        default: return .blue
        }
    }
}

import SwiftUI
import Combine

class WidgetRegistry: ObservableObject {
    static let shared = WidgetRegistry()
    
    @Published private(set) var plugins: [String: any AppWidgetPlugin] = [:]
    
    private init() {
        register(PowerFlowPlugin())
        register(BatterySpecsPlugin())
        register(BatteryHealthPlugin())
        register(HighPowerAppsPlugin())
        register(SystemMonitorPlugin())
    }
    
    func register(_ plugin: any AppWidgetPlugin) {
        plugins[plugin.id] = plugin
    }
    
    func plugin(for id: String) -> (any AppWidgetPlugin)? {
        return plugins[id]
    }
    
    var allPlugins: [any AppWidgetPlugin] {
        return Array(plugins.values).sorted { $0.id < $1.id }
    }
}


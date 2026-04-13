import SwiftUI

enum PowerFlowStyle: String, CaseIterable {
    case sankey = "sankey"
    case blocks = "blocks"
}

struct PowerFlowModuleView: View {
    var powerFlow: PowerFlowData
    @AppStorage("powerFlowStyle") private var style: PowerFlowStyle = .sankey
    
    var body: some View {
        switch style {
        case .sankey:
            SankeyPowerFlowView(powerFlow: powerFlow)
        case .blocks:
            BlockPowerFlowView(powerFlow: powerFlow)
        }
    }
}

// MARK: - Plugin Definition
struct PowerFlowPlugin: AppWidgetPlugin {
    let id = "powerFlow"
    let name = "实时能耗流"
    let icon = "bolt.horizontal"
    let hasSettings = false
    
    @MainActor
    var contentView: AnyView {
        AnyView(PowerFlowPluginContentView())
    }
    
    @MainActor
    var settingsView: AnyView {
        AnyView(EmptyView())
    }
}

private struct PowerFlowPluginContentView: View {
    @EnvironmentObject var viewModel: StatusViewModel
    
    var body: some View {
        PowerFlowModuleView(powerFlow: viewModel.powerFlow)
    }
}


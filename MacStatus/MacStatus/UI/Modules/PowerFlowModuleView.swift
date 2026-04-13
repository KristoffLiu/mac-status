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

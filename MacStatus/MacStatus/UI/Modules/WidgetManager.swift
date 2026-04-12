import SwiftUI
import Combine
import UniformTypeIdentifiers

enum PanelWidget: String, CaseIterable, Codable {
    case powerFlow
    case batteryDetail
    case highPowerApps
    
    var title: String {
        switch self {
        case .powerFlow: return "Real-time Energy Flow"
        case .batteryDetail: return "Battery Core Data"
        case .highPowerApps: return "High Power Apps"
        }
    }
}

class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    @Published var activeWidgets: [PanelWidget] = [.powerFlow, .batteryDetail, .highPowerApps] {
        didSet {
            save()
        }
    }
    
    var inactiveWidgets: [PanelWidget] {
        PanelWidget.allCases.filter { !activeWidgets.contains($0) }
    }
    
    init() {
        load()
    }
    
    func remove(_ widget: PanelWidget) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activeWidgets.removeAll { $0 == widget }
        }
    }
    
    func add(_ widget: PanelWidget) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if !activeWidgets.contains(widget) {
                activeWidgets.append(widget)
            }
        }
    }
    
    private func save() {
        let strings = activeWidgets.map { $0.rawValue }
        UserDefaults.standard.set(strings, forKey: "panelWidgetOrder")
    }
    
    private func load() {
        if let stored = UserDefaults.standard.stringArray(forKey: "panelWidgetOrder") {
            let widgets = stored.compactMap { PanelWidget(rawValue: $0) }
            if !widgets.isEmpty {
                self.activeWidgets = widgets
            }
        }
    }
}

struct WidgetDropDelegate: DropDelegate {
    let item: PanelWidget
    @Binding var activeWidgets: [PanelWidget]
    @Binding var draggingItem: PanelWidget?
    @ObservedObject var manager: WidgetManager

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        manager.activeWidgets = activeWidgets
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem = draggingItem,
              item != draggingItem,
              let from = manager.activeWidgets.firstIndex(of: draggingItem),
              let to = manager.activeWidgets.firstIndex(of: item) else { return }

        if from != to {
            withAnimation(.default) {
                manager.activeWidgets.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

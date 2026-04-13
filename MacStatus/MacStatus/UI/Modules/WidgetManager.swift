import SwiftUI
import Combine
import UniformTypeIdentifiers

enum PanelWidget: String, CaseIterable, Codable {
    case powerFlow
    case powerStatus
    case batterySpecs
    case batteryHealth
    case highPowerApps
    
    var title: String {
        switch self {
        case .powerFlow: return "Real-time Energy Flow"
        case .powerStatus: return "电源状态"
        case .batterySpecs: return "电池规格"
        case .batteryHealth: return "电池健康"
        case .highPowerApps: return "High Power Apps"
        }
    }
}

class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    @Published var activeWidgets: [PanelWidget] = [.powerFlow, .powerStatus, .batterySpecs, .batteryHealth] {
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
        // Automatically migrate users to the new arrangement
        if let stored = UserDefaults.standard.stringArray(forKey: "panelWidgetOrder") {
            var strings = stored
            
            // Clean out old widgets
            strings.removeAll { $0 == "powerData" || $0 == "batteryData" || $0 == "batteryDetail" }
            
            // Re-insert new group structure
            var insertions: [String] = ["powerStatus", "batterySpecs", "batteryHealth"]
            // Place them after powerFlow if it exists
            if let index = strings.firstIndex(of: "powerFlow") {
                strings.insert(contentsOf: insertions, at: index + 1)
            } else {
                strings.insert(contentsOf: insertions, at: 0)
            }
            
            let widgets = strings.compactMap { PanelWidget(rawValue: $0) }
            // Deduplicate preserving order
            var uniqueWidgets = [PanelWidget]()
            for w in widgets {
                if !uniqueWidgets.contains(w) {
                    uniqueWidgets.append(w)
                }
            }
            
            if !uniqueWidgets.isEmpty {
                self.activeWidgets = uniqueWidgets
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

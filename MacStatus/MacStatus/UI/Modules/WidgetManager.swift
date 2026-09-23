import SwiftUI
import Combine
import UniformTypeIdentifiers

class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    @Published var activeWidgets: [String] = WidgetCatalog.defaultOrder {
        didSet {
            save()
        }
    }
    
    var inactiveWidgets: [String] {
        WidgetCatalog.allIDs.filter { !activeWidgets.contains($0) }
    }
    
    init() {
        load()
    }
    
    func remove(_ widgetId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activeWidgets.removeAll { $0 == widgetId }
        }
    }
    
    func add(_ widgetId: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if !activeWidgets.contains(widgetId) {
                activeWidgets.append(widgetId)
            }
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        withAnimation {
            activeWidgets.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private func save() {
        UserDefaults.standard.set(activeWidgets, forKey: AppPreferenceKeys.panelWidgetOrder)
    }
    
    private func load() {
        // Automatically migrate users to the new arrangement
        if let stored = UserDefaults.standard.stringArray(forKey: AppPreferenceKeys.panelWidgetOrder) {
            var strings = stored
            
            let hasMigrated = UserDefaults.standard.bool(forKey: AppPreferenceKeys.hasMigratedToV2)
            if !hasMigrated {
                // Clean out old widgets
                strings.removeAll { $0 == "powerData" || $0 == "batteryData" || $0 == "batteryDetail" }
                
                // Re-insert new group structure
                let insertions: [String] = ["batterySpecs", "batteryHealth"]
                // Place them after powerFlow if it exists
                if let index = strings.firstIndex(of: "powerFlow") {
                    strings.insert(contentsOf: insertions, at: index + 1)
                } else {
                    strings.insert(contentsOf: insertions, at: 0)
                }
                
                UserDefaults.standard.set(true, forKey: AppPreferenceKeys.hasMigratedToV2)
            }
            
            self.activeWidgets = WidgetCatalog.sanitize(strings)
        }
    }
}

struct WidgetDropDelegate: DropDelegate {
    let item: String
    @Binding var activeWidgets: [String]
    @Binding var draggingItem: String?
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

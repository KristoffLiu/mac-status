import SwiftUI

@main
struct MacStatusApp: App {
    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("MacStatus", systemImage: "bolt.batteryblock.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window) // This enables the nice custom popover View
    }
}

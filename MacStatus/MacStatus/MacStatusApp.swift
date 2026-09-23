import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        AppPreferences.registerDefaults()
        AppPreferences.migrate()
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        Window("MacStatus", id: "settings") {
            AppWindowView()
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}

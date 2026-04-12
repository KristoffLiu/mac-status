import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // Dummy Settings scene to intercept SwiftUI's default start-up window behavior.
        // SwiftUI won't automatically open the secondary 'Window' scene on app launch.
        Settings { 
            EmptyView()
        }
        
        // Settings Window with Sidebar (Single Instance)
        Window("MacStatus 设置", id: "settings") {
            SettingsView()
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}

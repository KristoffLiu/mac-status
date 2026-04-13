import SwiftUI
import ServiceManagement

@main
struct MacStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settingsUpdateTrigger = UUID()

    init() {
        // Hide the dock icon to make it a pure Menu Bar agent
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            MainPanelView(viewModel: appDelegate.viewModel)
        } label: {
            if let image = appDelegate.generatedMenuImage {
                Image(nsImage: image)
            } else {
                Text("\(appDelegate.viewModel.currentCapacity)%")
            }
        }
        .menuBarExtraStyle(.window)

        Window("MacStatus", id: "settings") {
            AppWindowView()
                .onChange(of: appDelegate.viewModel.isCharging) { _ in settingsUpdateTrigger = UUID() }
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                    settingsUpdateTrigger = UUID()
                }
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentSize)
    }
}

import Combine
import ServiceManagement

@MainActor
protocol LoginItemManaging {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

@MainActor
private struct MainAppLoginItem: LoginItemManaging {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
final class LoginItemService: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var errorMessage: String?
    private let item: any LoginItemManaging

    init(item: (any LoginItemManaging)? = nil) {
        let item = item ?? MainAppLoginItem()
        self.item = item
        status = item.status
    }

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }
    func refresh() { status = item.status }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                if item.status == .notRegistered || item.status == .notFound { try item.register() }
            } else if item.status == .enabled || item.status == .requiresApproval {
                try item.unregister()
            }
        } catch { errorMessage = error.localizedDescription }
        refresh()
    }
}

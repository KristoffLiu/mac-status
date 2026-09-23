import Foundation
import ServiceManagement
import Testing
@testable import MacStatusCore

@MainActor
private final class FakeLoginItem: LoginItemManaging {
    var status: SMAppService.Status = .notRegistered
    var fail = false
    var registrations = 0
    func register() throws {
        if fail { throw NSError(domain: "test", code: 1) }
        registrations += 1
        status = .requiresApproval
    }
    func unregister() throws { status = .notRegistered }
}

@MainActor
struct LoginItemTests {
    @Test func registrationReflectsApprovalAndSystemChanges() {
        let fake = FakeLoginItem()
        let service = LoginItemService(item: fake)
        service.setEnabled(true)
        #expect(service.status == .requiresApproval)
        #expect(service.isRegistered)
        service.setEnabled(true)
        #expect(fake.registrations == 1)
        fake.status = .enabled
        service.refresh()
        #expect(service.status == .enabled)
        service.setEnabled(false)
        #expect(!service.isRegistered)
    }
    @Test func registrationFailureDoesNotPretendToEnable() {
        let fake = FakeLoginItem()
        fake.fail = true
        let service = LoginItemService(item: fake)
        service.setEnabled(true)
        #expect(!service.isRegistered)
        #expect(service.errorMessage != nil)
    }
}

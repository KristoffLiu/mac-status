import Foundation
import Testing
@testable import MacStatusCore

struct CommandRunnerTests {
    @Test func missingExecutableAndFailedExitReturnNoSample() async {
        #expect(await CommandRunner().run(executable: "/missing/macstatus-command", arguments: []) == nil)
        #expect(await CommandRunner().run(executable: "/usr/bin/false", arguments: []) == nil)
    }
    @Test func cancelledChildExitsPromptly() async throws {
        let start = Date()
        let task = Task { await CommandRunner().run(executable: "/bin/sleep", arguments: ["30"]) }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        #expect(await task.value == nil)
        #expect(Date().timeIntervalSince(start) < 3)
    }
    @Test func cancellationBeforeLaunchIsHandled() async {
        let task = Task { await CommandRunner().run(executable: "/bin/sleep", arguments: ["30"]) }
        task.cancel()
        #expect(await task.value == nil)
    }
}

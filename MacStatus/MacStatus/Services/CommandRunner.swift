import Foundation

/// Each invocation owns its cancellation state, including cancellation before launch.
nonisolated final class CommandRunner: Sendable {
    private final class Invocation: @unchecked Sendable {
        private let lock = NSLock()
        private var child: Process?
        private var cancelled = false

        func start(_ process: Process) throws -> Bool {
            try lock.withLock {
                guard !cancelled else { return false }
                child = process
                try process.run()
                return true
            }
        }

        func cancel() {
            lock.withLock {
                cancelled = true
                if let child, child.isRunning { child.terminate() }
            }
        }
    }

    func run(executable: String, arguments: [String]) async -> String? {
        let invocation = Invocation()
        return await withTaskCancellationHandler {
            guard !Task.isCancelled else { return nil }
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    let child = Process()
                    let pipe = Pipe()
                    child.executableURL = URL(fileURLWithPath: executable)
                    child.arguments = arguments
                    child.environment = ["LC_ALL": "C", "PATH": "/usr/bin:/bin"]
                    child.standardOutput = pipe
                    child.standardError = FileHandle.nullDevice
                    do {
                        guard try invocation.start(child) else { continuation.resume(returning: nil); return }
                        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5) { [weak invocation] in
                            invocation?.cancel()
                        }
                        let bytes = pipe.fileHandleForReading.readDataToEndOfFile()
                        child.waitUntilExit()
                        continuation.resume(returning: child.terminationStatus == 0 ? String(data: bytes, encoding: .utf8) : nil)
                    } catch {
                        continuation.resume(returning: nil)
                    }
                }
            }
        } onCancel: { invocation.cancel() }
    }
}

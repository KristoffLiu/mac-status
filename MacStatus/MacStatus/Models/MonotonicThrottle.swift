import Foundation

/// A small state machine for work that must be rate-limited by elapsed time.
/// Its input must come from a monotonic source such as systemUptime.
nonisolated struct MonotonicThrottle: Sendable {
    private(set) var lastRun: TimeInterval?

    mutating func shouldRun(now: TimeInterval, minimumInterval: TimeInterval, force: Bool = false) -> Bool {
        guard now.isFinite, minimumInterval.isFinite, minimumInterval >= 0 else { return false }
        if force || lastRun == nil || now < lastRun! || now - lastRun! >= minimumInterval {
            lastRun = now
            return true
        }
        return false
    }
}

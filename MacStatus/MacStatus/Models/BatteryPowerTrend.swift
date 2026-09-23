import Foundation

nonisolated struct BatteryPowerTrend: Sendable, Equatable {
    var averageWatts: Double?
    var energyWh: Double?
    var coverageSeconds: TimeInterval
    var isComplete: Bool

    static let empty = BatteryPowerTrend(
        averageWatts: nil,
        energyWh: nil,
        coverageSeconds: 0,
        isComplete: false
    )
}

/// Integrates signed battery power over a bounded one-minute window.
nonisolated struct BatteryPowerTrendAccumulator: Sendable {
    private struct Sample: Sendable {
        var uptime: TimeInterval
        var watts: Double
    }

    private struct Segment: Sendable {
        var start: Sample
        var end: Sample
    }

    private var previous: Sample?
    private var segments: [Segment] = []
    private let window: TimeInterval = 60
    private let minimumCoverage: TimeInterval = 48

    mutating func append(watts: Double, uptime: TimeInterval, maximumGap: TimeInterval) -> BatteryPowerTrend {
        guard watts.isFinite, uptime.isFinite else {
            reset()
            return .empty
        }
        let next = Sample(uptime: uptime, watts: watts)
        if let previous {
            let gap = uptime - previous.uptime
            if gap <= 0 || gap > maximumGap {
                reset()
            } else {
                segments.append(Segment(start: previous, end: next))
            }
        }
        previous = next
        return value(at: uptime)
    }

    mutating func reset() {
        previous = nil
        segments.removeAll(keepingCapacity: true)
    }

    private mutating func value(at now: TimeInterval) -> BatteryPowerTrend {
        let windowStart = now - window
        segments.removeAll { $0.end.uptime <= windowStart }

        var joules = 0.0
        var coverage = 0.0
        for segment in segments {
            let start = max(segment.start.uptime, windowStart)
            let end = min(segment.end.uptime, now)
            guard end > start else { continue }
            let duration = segment.end.uptime - segment.start.uptime
            let startFraction = (start - segment.start.uptime) / duration
            let endFraction = (end - segment.start.uptime) / duration
            let startWatts = segment.start.watts + (segment.end.watts - segment.start.watts) * startFraction
            let endWatts = segment.start.watts + (segment.end.watts - segment.start.watts) * endFraction
            let covered = end - start
            joules += (startWatts + endWatts) * 0.5 * covered
            coverage += covered
        }

        guard coverage > 0 else { return .empty }
        let energyWh = joules / 3600
        return BatteryPowerTrend(
            averageWatts: joules / coverage,
            energyWh: energyWh,
            coverageSeconds: coverage,
            isComplete: coverage >= minimumCoverage && coverage >= window - 0.001
        )
    }
}

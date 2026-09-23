import Foundation

/// Stabilizes the display direction without changing raw power readings or power accounting.
nonisolated struct PowerPresentationReducer: Sendable {
    private enum Candidate: Sendable, Equatable {
        case idle, charging, assisting
    }

    private var activity: BatteryActivityState = .unavailable
    private var candidate: Candidate?
    private var candidateStartedAt: TimeInterval?
    private var candidateCount = 0
    private var lastAcquisitionID: UInt64?
    private var lastSampleUptime: TimeInterval?
    private var trendAccumulator = BatteryPowerTrendAccumulator()
    private var trend = BatteryPowerTrend.empty

    private let enterThreshold = 1.0
    private let exitThreshold = 0.5
    private let minimumSpan: TimeInterval = 6
    private let minimumSamples = 4

    mutating func reset() {
        reset(to: .unavailable)
    }

    mutating func reduce(
        flow rawFlow: PowerFlowData,
        battery: BatteryData,
        expectedInterval: TimeInterval
    ) -> PowerFlowData {
        let flow = rawFlow

        guard let connected = flow.externalPowerConnected else {
            reset(to: .unavailable)
            return apply(activity, to: flow)
        }
        guard connected else {
            reset(to: .batteryPowered)
            return apply(.batteryPowered, to: flow)
        }
        guard !flow.readingsConflict,
              flow.batteryQuality == .measured,
              let power = battery.signedPowerWatts,
              let uptime = battery.sampledUptime,
              battery.acquisitionID != 0 else {
            reset(to: .unavailable)
            return apply(.unavailable, to: flow)
        }

        if lastAcquisitionID == battery.acquisitionID {
            return apply(activity, to: flow)
        }

        let safeExpectedInterval = expectedInterval.isFinite ? max(2, expectedInterval) : 2
        let maximumGap = safeExpectedInterval * 2 + 1
        if let lastSampleUptime, uptime < lastSampleUptime || uptime - lastSampleUptime > maximumGap {
            reset(to: .confirming)
        }
        lastAcquisitionID = battery.acquisitionID
        lastSampleUptime = uptime
        trend = trendAccumulator.append(watts: power, uptime: uptime, maximumGap: maximumGap)

        // An exact zero is already an unambiguous controller reading at startup.
        // Directional non-zero states still require sustained confirmation.
        if activity == .unavailable, abs(power) < 0.05 {
            activity = .idle
            candidate = nil
            candidateStartedAt = nil
            candidateCount = 0
            return apply(.idle, to: flow)
        }

        if activity == .charging, power > exitThreshold {
            return apply(.charging, to: flow)
        }
        if activity == .assisting, power < -exitThreshold {
            return apply(.assisting, to: flow)
        }
        if activity == .idle, abs(power) <= exitThreshold {
            return apply(.idle, to: flow)
        }

        let nextCandidate: Candidate?
        if power > enterThreshold {
            nextCandidate = .charging
        } else if power < -enterThreshold {
            nextCandidate = .assisting
        } else if abs(power) <= exitThreshold {
            nextCandidate = .idle
        } else {
            nextCandidate = nil
        }

        guard let nextCandidate else {
            candidate = nil
            candidateStartedAt = nil
            candidateCount = 0
            activity = .lowActivity
            return apply(activity, to: flow)
        }

        if candidate == nextCandidate {
            candidateCount += 1
        } else {
            candidate = nextCandidate
            candidateStartedAt = uptime
            candidateCount = 1
        }

        let span = uptime - (candidateStartedAt ?? uptime)
        if candidateCount >= minimumSamples, span >= minimumSpan {
            switch nextCandidate {
            case .idle: activity = .idle
            case .charging: activity = .charging
            case .assisting: activity = .assisting
            }
            candidate = nil
            candidateStartedAt = nil
            candidateCount = 0
        } else {
            activity = .confirming
        }
        return apply(activity, to: flow)
    }

    private mutating func reset(to newActivity: BatteryActivityState) {
        activity = newActivity
        candidate = nil
        candidateStartedAt = nil
        candidateCount = 0
        lastAcquisitionID = nil
        lastSampleUptime = nil
        trendAccumulator.reset()
        trend = .empty
    }

    private func apply(_ activity: BatteryActivityState, to rawFlow: PowerFlowData) -> PowerFlowData {
        var flow = rawFlow
        flow.batteryActivity = activity
        flow.batteryTrend = trend
        switch activity {
        case .charging:
            flow.isCharging = true
            flow.isDischarging = false
            flow.topology = .topologyA
        case .assisting:
            flow.isCharging = false
            flow.isDischarging = true
            flow.topology = .topologyB
        case .batteryPowered:
            flow.isCharging = false
            flow.isDischarging = true
            flow.topology = .topologyB
        case .unavailable, .confirming, .lowActivity, .idle:
            flow.isCharging = false
            flow.isDischarging = false
            if flow.externalPowerConnected == true { flow.topology = .topologyA }
        }
        return flow
    }
}

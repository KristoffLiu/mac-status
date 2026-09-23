import Foundation
import Testing
@testable import MacStatusCore

struct PowerPresentationTests {
    private func sample(
        watts: Double,
        id: UInt64,
        uptime: TimeInterval,
        reducer: inout PowerPresentationReducer
    ) -> PowerFlowData {
        var battery = BatteryData.empty
        battery.isAvailable = true
        battery.hasCurrentReading = true
        battery.externalConnected = true
        battery.voltage = 10_000
        battery.amperage = Int((watts * 100).rounded())
        battery.acquisitionID = id
        battery.sampledUptime = uptime
        let raw = PowerCalculationService.shared.calculateFlow(
            from: battery,
            sensors: PowerSensors(source: .ac, systemWatts: 30)
        )
        return reducer.reduce(flow: raw, battery: battery, expectedInterval: 2)
    }

    @Test func exactZeroIsImmediatelyShownAsIdle() {
        var reducer = PowerPresentationReducer()
        let flow = sample(watts: 0, id: 1, uptime: 0, reducer: &reducer)
        #expect(flow.batteryActivity == .idle)
        #expect(!flow.isCharging && !flow.isDischarging)
        #expect(flow.directionalBatteryPower == 0)
    }

    @Test func sustainedDischargeRequiresFourFreshSamplesAndSixSeconds() {
        var reducer = PowerPresentationReducer()
        for index in 0..<3 {
            let flow = sample(watts: -2, id: UInt64(index + 1), uptime: Double(index * 2), reducer: &reducer)
            #expect(flow.batteryActivity == .confirming)
            #expect(!flow.isDischarging)
        }
        let confirmed = sample(watts: -2, id: 4, uptime: 6, reducer: &reducer)
        #expect(confirmed.batteryActivity == .assisting)
        #expect(confirmed.isDischarging)
    }

    @Test func repeatedCachedSampleNeverAdvancesConfirmation() {
        var reducer = PowerPresentationReducer()
        for uptime in stride(from: 0.0, through: 10.0, by: 0.2) {
            let flow = sample(watts: -5, id: 1, uptime: uptime, reducer: &reducer)
            #expect(flow.batteryActivity == .confirming)
            #expect(!flow.isDischarging)
        }
    }

    @Test func alternatingDirectionDoesNotCommitEitherDirection() {
        var reducer = PowerPresentationReducer()
        for index in 0..<8 {
            let watts = index.isMultiple(of: 2) ? 2.0 : -2.0
            let flow = sample(watts: watts, id: UInt64(index + 1), uptime: Double(index * 2), reducer: &reducer)
            #expect(flow.batteryActivity == .confirming)
            #expect(!flow.isCharging && !flow.isDischarging)
        }
    }

    @Test func smallSignChangesSettleAsIdle() {
        var reducer = PowerPresentationReducer()
        var flow: PowerFlowData?
        for index in 0..<4 {
            let watts = index.isMultiple(of: 2) ? 0.12 : -0.12
            flow = sample(watts: watts, id: UInt64(index + 1), uptime: Double(index * 2), reducer: &reducer)
        }
        #expect(flow?.batteryActivity == .idle)
        #expect(flow?.signedBatteryPower == -0.12)
        #expect(flow?.batteryPower == 0.12)
        #expect(flow?.directionalBatteryPower == 0)
    }

    @Test func confirmedDirectionUsesHysteresisButStopsImmediatelyOnReversal() {
        var reducer = PowerPresentationReducer()
        for index in 0..<4 {
            _ = sample(watts: 2, id: UInt64(index + 1), uptime: Double(index * 2), reducer: &reducer)
        }
        let held = sample(watts: 0.6, id: 5, uptime: 8, reducer: &reducer)
        #expect(held.batteryActivity == .charging)
        #expect(held.isCharging)

        let reversed = sample(watts: -2, id: 6, uptime: 10, reducer: &reducer)
        #expect(reversed.batteryActivity == .confirming)
        #expect(!reversed.isCharging && !reversed.isDischarging)
    }

    @Test func unpluggingBypassesPresentationDelay() {
        var reducer = PowerPresentationReducer()
        var battery = BatteryData.empty
        battery.isAvailable = true
        battery.hasCurrentReading = true
        battery.voltage = 10_000
        battery.amperage = -200
        battery.acquisitionID = 1
        battery.sampledUptime = 0
        let raw = PowerCalculationService.shared.calculateFlow(
            from: battery,
            sensors: PowerSensors(source: .battery, systemWatts: 2)
        )
        let flow = reducer.reduce(flow: raw, battery: battery, expectedInterval: 2)
        #expect(flow.batteryActivity == .batteryPowered)
        #expect(flow.isDischarging)
    }

    @Test func sustainedSmallDischargeRemainsVisibleInMinuteTrend() {
        var reducer = PowerPresentationReducer()
        var flow: PowerFlowData?
        for index in 0...30 {
            flow = sample(
                watts: -0.3,
                id: UInt64(index + 1),
                uptime: Double(index * 2),
                reducer: &reducer
            )
        }
        #expect(flow?.batteryActivity == .idle)
        #expect(flow?.batteryTrend.isComplete == true)
        #expect(abs((flow?.batteryTrend.averageWatts ?? 0) + 0.3) < 0.000_001)
        #expect(abs((flow?.batteryTrend.energyWh ?? 0) + 0.005) < 0.000_001)
    }

    @Test func alternatingPowerIntegratesWithItsSign() {
        var reducer = PowerPresentationReducer()
        var flow: PowerFlowData?
        for index in 0...30 {
            flow = sample(
                watts: index.isMultiple(of: 2) ? 2 : -2,
                id: UInt64(index + 1),
                uptime: Double(index * 2),
                reducer: &reducer
            )
        }
        #expect(flow?.batteryTrend.isComplete == true)
        #expect(abs(flow?.batteryTrend.averageWatts ?? 1) < 0.000_001)
        #expect(abs(flow?.batteryTrend.energyWh ?? 1) < 0.000_001)
    }

    @Test func lifecycleResetRequiresFreshConfirmation() {
        var reducer = PowerPresentationReducer()
        for index in 0..<4 {
            _ = sample(watts: -2, id: UInt64(index + 1), uptime: Double(index * 2), reducer: &reducer)
        }
        reducer.reset()
        let flow = sample(watts: -2, id: 4, uptime: 6, reducer: &reducer)
        #expect(flow.batteryActivity == .confirming)
        #expect(!flow.isDischarging)
        #expect(flow.batteryTrend == .empty)
    }

    @Test func estimatedBatteryDirectionIsNeverConfirmedAsMeasured() {
        var reducer = PowerPresentationReducer()
        var battery = BatteryData.empty
        battery.isAvailable = true
        battery.hasCurrentReading = false
        battery.externalConnected = true
        battery.acquisitionID = 1
        battery.sampledUptime = 0
        let raw = PowerCalculationService.shared.calculateFlow(
            from: battery,
            sensors: PowerSensors(source: .ac, systemWatts: 30, adapterVoltage: 20, adapterCurrent: 1)
        )
        let flow = reducer.reduce(flow: raw, battery: battery, expectedInterval: 2)
        #expect(raw.isDischarging)
        #expect(raw.batteryQuality == .estimated)
        #expect(flow.batteryActivity == .unavailable)
        #expect(!flow.isCharging && !flow.isDischarging)
    }
}

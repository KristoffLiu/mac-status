import Testing
@testable import MacStatusCore

struct PowerCalculationTests {
    func battery(amperage: Int = -1000, rated: Int = 20, intake: Double = 20) -> BatteryData {
        var data = BatteryData.empty
        data.isAvailable = true
        data.hasCurrentReading = true
        data.voltage = 10000
        data.amperage = amperage
        data.adapterWatts = rated
        data.adapter = AdapterInfo(id: 0, familyCode: 0, name: "Fixture", designWatts: rated, realTimeWatts: intake, activeProfileIndex: 0, profiles: [])
        return data
    }

    @Test func hybridSupplyPreservesBatteryContribution() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(), sensors: PowerSensors(source: .ac, systemWatts: 30, adapterVoltage: 20, adapterCurrent: 1))
        #expect(flow.isDischarging)
        #expect(flow.batteryPower == 10)
        #expect(flow.adapterPower + flow.batteryPower == flow.systemPower)
    }

    @Test func unpluggingOverridesCachedAdapter() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(), sensors: PowerSensors(source: .battery, systemWatts: 30, adapterVoltage: 20, adapterCurrent: 1))
        #expect(flow.adapterPower == 0)
        #expect(flow.isDischarging)
        #expect(flow.batteryPower == flow.systemPower)
    }

    @Test func ratedPowerIsNeverSystemLoad() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 0, rated: 65, intake: 0), sensors: PowerSensors(source: .ac))
        #expect(flow.systemPower == 0)
    }
}

extension PowerCalculationTests {
    @Test func chargingAndBypassUseLiveMeasurements() {
        for (adapter, system, expected) in [(50.0, 30.0, 20.0), (30.0, 30.0, 0.0)] {
            let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: Int(expected * 100)), sensors: PowerSensors(source: .ac, systemWatts: system, adapterVoltage: 10, adapterCurrent: adapter / 10))
            #expect(flow.batteryPower == expected)
            #expect(flow.isCharging == (expected > 0))
            #expect(!flow.isDischarging)
            #expect(flow.batteryQuality == .measured)
        }
    }

    @Test func absenceAndZeroAreDifferent() {
        let unknown = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 0, rated: 65, intake: 0), sensors: PowerSensors(source: .ac))
        #expect(unknown.systemQuality == .unavailable)
        #expect(!unknown.isComplete)
        #expect(unknown.systemQuality.format(unknown.systemPower) == "—")
        let zero = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 0), sensors: PowerSensors(source: .ac, systemWatts: 0, adapterVoltage: 20, adapterCurrent: 0))
        #expect(zero.systemQuality == .measured)
        #expect(zero.isComplete)
        #expect(zero.systemQuality.format(zero.systemPower) == "0.0 W")
    }

    @Test func batteryOnlyFallsBackToSignedCurrent() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(), sensors: PowerSensors(source: .battery))
        #expect(flow.systemPower == 10)
        #expect(flow.systemQuality == .estimated)
        #expect(flow.adapterPower == 0)
        let stale = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 1000), sensors: PowerSensors(source: .battery))
        #expect(!stale.isCharging)
        #expect(stale.systemQuality == .unavailable)
    }

    @Test func inconsistentInputsNeverProduceNegativeSystemLoad() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 3000, intake: 10), sensors: PowerSensors(source: .ac))
        #expect(flow.systemPower == 0)
        #expect(flow.systemQuality == .unavailable)
        #expect(flow.batteryQuality == .unavailable)
    }

    @Test func unknownSourceDoesNotAssertCharging() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 1000), sensors: PowerSensors(systemWatts: 20))
        #expect(flow.externalPowerConnected == nil)
        #expect(!flow.isCharging)
        #expect(!flow.isDischarging)
        #expect(!flow.isComplete)
    }

    @Test func malformedReadingsAreRejected() {
        for value in [Double.nan, Double.infinity, -1, 2000] {
            let flow = PowerCalculationService.shared.calculateFlow(from: .empty, sensors: PowerSensors(source: .unknown, systemWatts: value))
            #expect(flow.systemQuality == .unavailable)
            #expect(flow.systemPower.isFinite && flow.systemPower >= 0)
        }
    }

    @Test func measuredPowerGridConservesEnergy() {
        for adapter in stride(from: 0, through: 140, by: 5) {
            for system in stride(from: 0, through: 140, by: 5) {
                let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: (adapter - system) * 100), sensors: PowerSensors(source: .ac, systemWatts: Double(system), adapterVoltage: 10, adapterCurrent: Double(adapter) / 10))
                let balance = flow.adapterPower + (flow.isDischarging ? flow.batteryPower : -flow.batteryPower)
                #expect(abs(balance - flow.systemPower) < 0.000001)
                #expect(!(flow.isCharging && flow.isDischarging))
                #expect(flow.batteryPower >= 0 && flow.systemPower >= 0)
            }
        }
    }

    @Test func breakdownIsOptInAndCannotExceedSystemPower() {
        var sensors = PowerSensors(source: .ac, systemWatts: 30, adapterVoltage: 20, adapterCurrent: 2, cpuTotal: 0.9, gpuUtilization: 0.8, coreCount: 8, topApp: TopAppUsage(name: "Editor", cpuPercent: 300))
        #expect(PowerCalculationService.shared.calculateFlow(from: battery(), sensors: sensors).coreWatts == nil)
        sensors.includeBreakdown = true
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(), sensors: sensors)
        let total = (flow.coreWatts ?? 0) + (flow.peripheralWatts ?? 0) + (flow.topAppWatts ?? 0)
        #expect(abs(total - 30) < 0.000001)
    }

    @Test func capacityUnitsRemainDistinct() {
        var data = battery()
        data.currentCapacity = 80
        data.maxCapacity = 5000
        data.designCapacity = 6000
        #expect(data.currentCapacity == 80)
        #expect(data.healthPercent == 83)
        #expect(BatteryData.empty.healthPercent == nil)
    }
}

extension PowerCalculationTests {
    @Test func lowLoadPowerDomainDifferenceDoesNotBlockTheUI() {
        let flow = PowerCalculationService.shared.calculateFlow(
            from: battery(amperage: 0, intake: 11.9),
            sensors: PowerSensors(source: .ac, systemWatts: 9.2, adapterVoltage: 10, adapterCurrent: 1.19)
        )
        #expect(!flow.readingsConflict)
        #expect(flow.powerDomainsDiffer)
        #expect(flow.batteryPower == 0)
        #expect(!flow.isCharging && !flow.isDischarging)
        #expect(abs(flow.adapterPower - 11.9) < 0.000_001)
        #expect(abs(flow.adapterSupplyPower - 9.2) < 0.000_001)
        #expect(abs(flow.systemPower - 9.2) < 0.000_001)
    }

    @Test func differentPowerDomainsDoNotInventBatteryDischarge() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 0, intake: 12.8), sensors: PowerSensors(source: .ac, systemWatts: 25.2, adapterVoltage: 20, adapterCurrent: 0.64))
        #expect(!flow.readingsConflict)
        #expect(flow.powerDomainsDiffer)
        #expect(flow.isComplete)
        #expect(!flow.isCharging && !flow.isDischarging)
        #expect(flow.batteryPower == 0)
    }
    @Test func smallSensorDifferencesPreserveMeasuredValues() {
        let flow = PowerCalculationService.shared.calculateFlow(from: battery(amperage: 0), sensors: PowerSensors(source: .ac, systemWatts: 25, adapterVoltage: 20, adapterCurrent: 1.3))
        #expect(flow.isComplete)
        #expect(flow.adapterPower == 26)
        #expect(flow.adapterQuality == .measured)
        #expect(!flow.powerDomainsDiffer)
        #expect(!flow.isCharging && !flow.isDischarging)
    }
    @Test func physicallyImpossibleMeasuredBatteryFlowStillConflicts() {
        let flow = PowerCalculationService.shared.calculateFlow(
            from: battery(amperage: -3000),
            sensors: PowerSensors(source: .ac, systemWatts: 20, adapterVoltage: 10, adapterCurrent: 1)
        )
        #expect(flow.readingsConflict)
        #expect(!flow.isComplete)
    }
    @Test func absentBatteryCurrentCanBeEstimatedFromMeasuredPower() {
        var data = battery()
        data.hasCurrentReading = false
        let flow = PowerCalculationService.shared.calculateFlow(from: data, sensors: PowerSensors(source: .ac, systemWatts: 30, adapterVoltage: 20, adapterCurrent: 1))
        #expect(flow.isDischarging && flow.isComplete)
        #expect(flow.batteryQuality == .estimated)
        #expect(flow.batteryPower == 10)
    }
}

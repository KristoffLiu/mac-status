import Testing
@testable import MacStatusCore

struct SamplingTests {
    @Test func recordedAdapterReplaysSamplesAndHoldsTheLastValue() async {
        var firstBattery = BatteryData.empty
        firstBattery.acquisitionID = 1
        var secondBattery = BatteryData.empty
        secondBattery.acquisitionID = 2
        let adapter = RecordedPowerSampleAdapter(samples: [
            PowerSample(battery: firstBattery, sensors: PowerSensors(source: .battery)),
            PowerSample(battery: secondBattery, sensors: PowerSensors(source: .ac)),
        ])

        #expect(await adapter.sample().battery.acquisitionID == 1)
        #expect(await adapter.sample().battery.acquisitionID == 2)
        #expect(await adapter.sample().battery.acquisitionID == 2)
    }

    @Test func statusSnapshotCarriesOneBreakdownSampleAcrossTheCalculationSeam() {
        let metrics = PowerBreakdownMetrics(
            cpuTotal: 0.4,
            gpuUtilization: 0.2,
            coreCount: 10,
            sampledUptime: 42
        )
        let snapshot = StatusSnapshot(
            power: PowerSample(battery: .empty, sensors: PowerSensors(source: .ac, systemWatts: 20)),
            breakdown: metrics,
            topApp: TopAppUsage(name: "Editor", cpuPercent: 30),
            sampledUptime: 43
        )

        #expect(snapshot.sensors.includeBreakdown)
        #expect(snapshot.sensors.cpuTotal == 0.4)
        #expect(snapshot.sensors.topApp?.name == "Editor")
        #expect(snapshot.sampledUptime == 43)
        #expect(snapshot.breakdownSampledUptime == 42)
    }

    @Test func backgroundStopsAllExpensiveWork() {
        let policy = SamplingPolicy(widgets: ["systemMonitor", "highPowerApps", "powerFlow"], threeStage: true)
        #expect(policy.tickInterval == 10)
        #expect(!policy.needsSystemMetrics)
        #expect(!policy.needsHighPowerApps)
        #expect(!policy.needsBreakdown)
    }
    @Test func removingWidgetsStopsTheirWork() {
        var policy = SamplingPolicy(panelVisible: true, widgets: ["systemMonitor", "highPowerApps", "powerFlow"], threeStage: true)
        #expect(policy.needsSystemMetrics && policy.needsHighPowerApps && policy.needsBreakdown)
        policy.widgets = []
        #expect(!policy.needsSystemMetrics && !policy.needsHighPowerApps && !policy.needsBreakdown)
    }
    @Test func sleepingStopsEveryTick() {
        let policy = SamplingPolicy(panelVisible: true, sleeping: true, widgets: ["systemMonitor", "highPowerApps", "powerFlow"], threeStage: true)
        #expect(policy.tickInterval == nil)
        #expect(!policy.needsSystemMetrics && !policy.needsHighPowerApps && !policy.needsBreakdown)
    }
    @Test func hiddenBreakdownDoesNotPollApps() {
        var policy = SamplingPolicy(panelVisible: true, widgets: ["powerFlow"], threeStage: false)
        #expect(!policy.needsBreakdown && !policy.needsSystemMetrics)
        policy.threeStage = true
        policy.flowStyle = "twin"
        #expect(!policy.needsBreakdown)
        policy.flowStyle = "sankey"
        #expect(policy.needsBreakdown)
    }
    @Test func refreshPreferencesHaveBounds() {
        for value in [Double.nan, .infinity, -2, 0, 0.01, 100] { #expect(SamplingPolicy.clampInterval(value) == 1) }
        #expect(SamplingPolicy(backgroundInterval: 2).tickInterval == 2)
        #expect(SamplingPolicy(backgroundInterval: .nan).tickInterval == 10)
        #expect(SamplingPolicy.clampInterval(0.2) == 0.2)
        #expect(SamplingPolicy(activeInterval: 0.2).appInterval == 2)
        #expect(SamplingPolicy(activeInterval: 2).appInterval == 4)
    }
}

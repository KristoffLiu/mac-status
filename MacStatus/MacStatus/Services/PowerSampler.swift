import Foundation
import IOKit.ps

/// Cache ownership is confined to this serial queue. No UI state is accessed here.
nonisolated final class PowerSampler: @unchecked Sendable, PowerSampleAdapter {
    static let shared = PowerSampler()
    private let queue = DispatchQueue(label: "MacStatus.power-sampling", qos: .utility)
    private var cachedBattery = BatteryData.empty
    private var batteryRefresh = MonotonicThrottle()
    private var lastSource = PowerSource.unknown
    private var acquisitionID: UInt64 = 0

    func sample() async -> PowerSample {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
                let name = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as? String
                let source: PowerSource = name == "AC Power" ? .ac : (name == "Battery Power" ? .battery : .unknown)
                let now = ProcessInfo.processInfo.systemUptime
                if batteryRefresh.shouldRun(now: now, minimumInterval: 2, force: source != lastSource) {
                    cachedBattery = BatteryService.shared.fetchBatteryData()
                    acquisitionID &+= 1
                    cachedBattery.acquisitionID = acquisitionID
                    cachedBattery.sampledUptime = now
                    lastSource = source
                }
                var data = cachedBattery
                if source == .battery {
                    data.adapter = nil
                    data.adapterWatts = 0
                    data.externalConnected = false
                    data.isCharging = false
                } else if source == .ac {
                    data.externalConnected = true
                }
                let smc = SMCService.shared
                let sensors = PowerSensors(source: source, systemWatts: smc.systemTotalPower,
                                           adapterVoltage: smc.adapterVoltage, adapterCurrent: smc.adapterCurrent)
                continuation.resume(returning: PowerSample(battery: data, sensors: sensors))
            }
        }
    }
}

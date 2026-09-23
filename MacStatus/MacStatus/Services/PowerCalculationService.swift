import Foundation

/// Deterministic power accounting. Rated adapter capacity is deliberately never an input.
nonisolated final class PowerCalculationService: Sendable {
    static let shared = PowerCalculationService()
    private init() {}

    func calculateFlow(from data: BatteryData, sensors: PowerSensors) -> PowerFlowData {
        let source = sensors.source == .unknown
            ? data.externalConnected.map { $0 ? PowerSource.ac : .battery } ?? .unknown
            : sensors.source
        var system = validPower(sensors.systemWatts)
        let volts = valid(sensors.adapterVoltage, in: 4...60)
        let amps = valid(sensors.adapterCurrent, in: 0...20)
        var adapter = volts.flatMap { v in amps.flatMap { validPower(v * $0) } }
        if adapter == nil, let info = data.adapter,
           info.hasRealTimePower || info.realTimeWatts > 0 {
            adapter = validPower(info.realTimeWatts)
        }
        var signedBattery: Double? = data.isAvailable && data.hasCurrentReading && data.voltage > 0
            ? Double(data.voltage) * Double(data.amperage) / 1_000_000 : nil
        if let watts = signedBattery, !watts.isFinite || abs(watts) > 1000 { signedBattery = nil }
        var systemQuality: ReadingQuality = system == nil ? .unavailable : .measured
        var adapterQuality: ReadingQuality = adapter == nil ? .unavailable : .measured
        var batteryQuality: ReadingQuality = signedBattery == nil ? .unavailable : .measured

        var readingsConflict = false
        var powerDomainsDiffer = false

        switch source {
        case .battery:
            // The current system source wins over AppleSmartBattery's cached adapter dictionary.
            adapter = 0
            adapterQuality = .measured
            if let watts = system {
                signedBattery = -watts
                batteryQuality = .estimated
            } else if let battery = signedBattery, battery <= 0 {
                system = -battery
                systemQuality = .estimated
            } else {
                // A positive battery current after unplugging is stale, not a charging state.
                signedBattery = nil
                batteryQuality = .unavailable
            }
        case .ac:
            if let input = adapter, let load = system {
                if let battery = signedBattery {
                    // SMC keys can describe different power domains on different Macs.
                    // Never invent battery discharge from disagreement with the battery controller.
                    let expectedInput = load + battery
                    let tolerance = max(2, max(input, load) * 0.1)
                    if expectedInput < 0 {
                        readingsConflict = true
                    } else if abs(input - expectedInput) > tolerance {
                        // These SMC values can cover different power domains and sample windows.
                        // Preserve every measured value and trust the battery controller for direction.
                        powerDomainsDiffer = true
                    }
                } else if data.isAvailable {
                    signedBattery = input - load
                    batteryQuality = .estimated
                }
            } else if let battery = signedBattery {
                if let load = system {
                    if let inferred = validPower(load + battery) {
                        adapter = inferred
                        adapterQuality = .estimated
                    } else {
                        signedBattery = nil
                        batteryQuality = .unavailable
                    }
                } else if let input = adapter {
                    if let inferred = validPower(input - battery) {
                        system = inferred
                        systemQuality = .estimated
                    } else {
                        signedBattery = nil
                        batteryQuality = .unavailable
                    }
                }
            }
        case .unknown:
            adapter = nil
            signedBattery = nil
            adapterQuality = .unavailable
            batteryQuality = .unavailable
        }

        let charging = !readingsConflict && source == .ac && (signedBattery ?? 0) > 0
        let discharging = source == .battery || (!readingsConflict && source == .ac && (signedBattery ?? 0) < 0)
        var flow = PowerFlowData(
            adapterPower: adapter ?? 0, batteryPower: abs(signedBattery ?? 0), systemPower: system ?? 0,
            isCharging: charging, isDischarging: discharging,
            topology: source == .ac && !discharging ? .topologyA : .topologyB,
            adapterVoltage: source == .ac ? volts : nil, adapterCurrent: source == .ac ? amps : nil,
            adapterQuality: adapterQuality, batteryQuality: batteryQuality, systemQuality: systemQuality,
            externalPowerConnected: source == .unknown ? nil : source == .ac, readingsConflict: readingsConflict,
            powerDomainsDiffer: powerDomainsDiffer,
            signedBatteryPower: signedBattery,
            batteryActivity: source == .battery ? .batteryPowered : (charging ? .charging : (discharging ? .assisting : .idle))
        )
        if sensors.includeBreakdown, let system {
            // A heuristic CPU/GPU allocation, not per-process measured watts.
            let cpu = valid(sensors.cpuTotal, in: 0...1) ?? 0
            let gpu = valid(sensors.gpuUtilization, in: 0...1) ?? 0
            var core = min(system, 2 + cpu * 20 + gpu * 10)
            if let app = sensors.topApp, app.cpuPercent.isFinite, app.cpuPercent > 5 {
                let fraction = min(1, app.cpuPercent / max(Double(max(1, sensors.coreCount)) * 100 * cpu, 1))
                let watts = max(0, core - 2) * fraction
                if watts >= 0.5 {
                    flow.topAppWatts = watts
                    flow.topAppName = app.name
                    core -= watts
                }
            }
            flow.coreWatts = core
            flow.peripheralWatts = max(0, system - core - (flow.topAppWatts ?? 0))
        }
        return flow
    }

    private func validPower(_ value: Double?) -> Double? { valid(value, in: 0...1000) }
    private func valid(_ value: Double?, in range: ClosedRange<Double>) -> Double? {
        guard let value, value.isFinite, range.contains(value) else { return nil }
        return value
    }
}

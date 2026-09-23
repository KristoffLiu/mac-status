import Foundation

// MARK: - Adapter & PD Profile Structures
nonisolated struct PDProfile: Identifiable, Sendable, Equatable {
    var id: Int { index }
    var index: Int
    var maxVoltage: Double // In Volts (hardware provides mV)
    var maxCurrent: Double // In Amps (hardware provides mA)

    var maxWatts: Double {
        return maxVoltage * maxCurrent
    }
}

nonisolated struct AdapterInfo: Sendable, Equatable {
    var id: Int
    var familyCode: Int
    var name: String
    var manufacturer: String?
    var designWatts: Int
    var realTimeWatts: Double // Real-time intake from PMU
    var activeProfileIndex: Int
    var profiles: [PDProfile]

    var current: Double?
    var voltage: Double?
    var watts: Double?

    var hasRealTimePower = false

    var activeProfile: PDProfile? {
        profiles.first { $0.index == activeProfileIndex }
    }
}

nonisolated struct BatteryData: Sendable, Equatable {
    var voltage: Int
    var amperage: Int
    var isCharging: Bool
    var currentCapacity: Int
    var maxCapacity: Int
    var designCapacity: Int
    var cycleCount: Int
    var temperature: Double
    var adapterWatts: Int // Legacy
    var adapter: AdapterInfo? // Advanced Adapter Info

    var appleRawMaxCapacity: Int?
    var appleMaxCapacity: Int?
    var timeRemaining: Int?

    var isAvailable = false
    var hasCurrentReading = false
    var externalConnected: Bool?
    var condition: String?
    var currentCapacityMAh: Int?
    var sampledAt: Date?
    /// Changes only when AppleSmartBattery is read again, not when a cached sample is reused.
    var acquisitionID: UInt64 = 0
    /// Monotonic time of the application-level acquisition.
    var sampledUptime: TimeInterval?

    var signedPowerWatts: Double? {
        guard isAvailable, hasCurrentReading, voltage > 0 else { return nil }
        let value = Double(voltage) * Double(amperage) / 1_000_000
        guard value.isFinite, abs(value) <= 1000 else { return nil }
        return value
    }

    var healthPercent: Int? {
        guard isAvailable, maxCapacity > 100, designCapacity > 100 else { return nil }
        return Int(min(100, max(0, Double(maxCapacity) / Double(designCapacity) * 100)))
    }

    static let empty = BatteryData(
        voltage: 0, amperage: 0, isCharging: false, currentCapacity: 0, maxCapacity: 0,
        designCapacity: 0, cycleCount: 0, temperature: 0.0, adapterWatts: 0, adapter: nil,
        appleRawMaxCapacity: nil, appleMaxCapacity: nil, timeRemaining: nil
    )
}

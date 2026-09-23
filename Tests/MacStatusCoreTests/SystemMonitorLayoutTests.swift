import Foundation
import Testing
@testable import MacStatusCore

struct SystemMonitorLayoutTests {
    @Test func pixelGridAlwaysFitsIncludingGroupedGaps() {
        for width in [0.0, 3, 83, 178, 368] {
            for height in [8.0, 24, 52, 200] {
                for size in [2.0, 5, 10, 20] {
                    for grouping in 0...3 {
                        let grid = MonitorPixelGrid(width: width, height: height, size: size, gap: 2.5, grouping: grouping)
                        #expect(grid.width <= width)
                        #expect(grid.height <= height)
                        if grid.columns > 0 { #expect(grid.x(grid.columns - 1) + grid.size <= width) }
                        if grid.rows > 0 { #expect(grid.y(grid.rows - 1) + grid.size <= height) }
                    }
                }
            }
        }
    }

    @Test func emptyOrInvalidSamplesAreSafe() {
        #expect(MonitorHistory.columns([], count: 4) == [0, 0, 0, 0])
        #expect(MonitorHistory.columns([1], count: 0).isEmpty)
        #expect(MonitorHistory.columns([.nan, .infinity, -1, 2], count: 4) == [0, 0, 0, 1])
        let grid = MonitorPixelGrid(width: 100, height: 52, size: .nan, gap: .infinity, grouping: 3)
        #expect(grid.width <= 100)
        #expect(grid.height <= 52)
    }

    @Test func resizingKeepsOldSpikesAndNewestSamples() {
        let samples = [0.0, 1, 0, 0, 0, 0, 0.5, 0]
        #expect(MonitorHistory.columns(samples, count: 2) == [1, 0.5])
        #expect(MonitorHistory.columns([0.2, 0.8], count: 4) == [0.2, 0.2, 0.8, 0.8])
    }

    @Test func throughputUsesOneScaleForBothDirectionsAndAllTimes() {
        let down = [10.0, 100, 10]
        let up = [5.0, 50, 5]
        let scale = MonitorHistory.scale(down, up, minimum: 1)
        #expect(scale == 100)
        #expect(MonitorHistory.columns(down, count: 3, scale: scale) == [0.1, 1, 0.1])
        #expect(MonitorHistory.columns(up, count: 3, scale: scale) == [0.05, 0.5, 0.05])
    }

    @Test func legacyLayoutMigratesOnceAndPreservesHiddenGroups() {
        let name = "MacStatusCoreTests.monitorMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        AppPreferences.registerDefaults(defaults)
        defaults.set(false, forKey: AppPreferenceKeys.sysMonShowCompute)
        defaults.set(false, forKey: AppPreferenceKeys.sysMonShowNetDisk)
        defaults.set(5.0, forKey: AppPreferenceKeys.sysMonChartPixelSize)
        defaults.set(1.5, forKey: AppPreferenceKeys.sysMonPixelDensity)
        AppPreferences.migrate(defaults)
        #expect(!defaults.bool(forKey: AppPreferenceKeys.sysMonShowCPU))
        #expect(!defaults.bool(forKey: AppPreferenceKeys.sysMonShowGPU))
        #expect(!defaults.bool(forKey: AppPreferenceKeys.sysMonShowNetwork))
        #expect(!defaults.bool(forKey: AppPreferenceKeys.sysMonShowDisk))
        #expect(defaults.double(forKey: AppPreferenceKeys.sysMonMemoryHeight) == 76.5)
        defaults.set(128.0, forKey: AppPreferenceKeys.sysMonMemoryHeight)
        defaults.set(true, forKey: AppPreferenceKeys.sysMonShowCPU)
        AppPreferences.migrate(defaults)
        #expect(defaults.double(forKey: AppPreferenceKeys.sysMonMemoryHeight) == 128)
        #expect(defaults.bool(forKey: AppPreferenceKeys.sysMonShowCPU))
    }

    @Test func resetOnlyAffectsSystemMonitorAndDoesNotRemigrate() {
        let name = "MacStatusCoreTests.monitorReset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        AppPreferences.registerDefaults(defaults)
        defaults.set(180.0, forKey: AppPreferenceKeys.sysMonMemoryHeight)
        defaults.set(false, forKey: AppPreferenceKeys.sysMonShowCompute)
        defaults.set(false, forKey: AppPreferenceKeys.sysMonShowCPU)
        defaults.set("dark", forKey: AppPreferenceKeys.panelTheme)
        AppPreferences.resetSystemMonitor(defaults)
        AppPreferences.migrate(defaults)
        #expect(defaults.double(forKey: AppPreferenceKeys.sysMonMemoryHeight) == 64)
        #expect(defaults.bool(forKey: AppPreferenceKeys.sysMonShowCPU))
        #expect(defaults.string(forKey: AppPreferenceKeys.panelTheme) == "dark")
    }
}

import Foundation
import Testing
@testable import MacStatusCore

struct PreferencesAndTimingTests {
    @Test func rightClickRoutesToConfiguredCommand() {
        #expect(MenuBarInteraction.command(for: .left, rightClickAction: .quit) == .togglePanel)
        #expect(MenuBarInteraction.command(for: .right, rightClickAction: .sameAsLeft) == .togglePanel)
        #expect(MenuBarInteraction.command(for: .right, rightClickAction: .quit) == .terminate)
    }

    @Test func legacyRightClickValuesMigrateWithoutChangingMeaning() {
        let name = "MacStatusCoreTests.preferences.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }

        defaults.set("退出应用", forKey: AppPreferenceKeys.menuRightClickAction)
        AppPreferences.migrate(defaults)

        #expect(defaults.string(forKey: AppPreferenceKeys.menuRightClickAction) == MenuBarRightClickAction.quit.rawValue)
        #expect(AppPreferences.rightClickAction(defaults) == .quit)
    }

    @Test func menuBarResetCoversEveryOwnedMenuBarSettingOnly() {
        let name = "MacStatusCoreTests.reset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }

        for key in AppPreferences.menuBarKeys { defaults.set("changed", forKey: key) }
        defaults.set(true, forKey: AppPreferenceKeys.autoHidePanel)

        AppPreferences.resetMenuBar(defaults)

        let persisted = defaults.persistentDomain(forName: name) ?? [:]
        #expect(AppPreferences.menuBarKeys.allSatisfy { persisted[$0] == nil })
        #expect(defaults.bool(forKey: AppPreferenceKeys.autoHidePanel))
    }

    @Test func registeredDefaultsProvideOneAuthoritativeSchema() {
        let name = "MacStatusCoreTests.defaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }

        AppPreferences.registerDefaults(defaults)

        #expect(defaults.string(forKey: AppPreferenceKeys.powerFlowStyle) == "cards")
        #expect(defaults.string(forKey: AppPreferenceKeys.menuRightClickAction) == MenuBarRightClickAction.sameAsLeft.rawValue)
        #expect(defaults.stringArray(forKey: AppPreferenceKeys.panelWidgetOrder) == AppPreferences.defaultWidgetOrder)
        #expect(defaults.bool(forKey: AppPreferenceKeys.showPercentage))
    }

    @Test func monotonicThrottleRunsOnlyAfterElapsedInterval() {
        var throttle = MonotonicThrottle()
        let first = throttle.shouldRun(now: 100, minimumInterval: 2)
        let early = throttle.shouldRun(now: 101.9, minimumInterval: 2)
        let elapsed = throttle.shouldRun(now: 102, minimumInterval: 2)
        let restartedClock = throttle.shouldRun(now: 1, minimumInterval: 2)
        #expect(first)
        #expect(!early)
        #expect(elapsed)
        #expect(restartedClock)
    }
}

import Foundation

nonisolated enum MenuBarRightClickAction: String, CaseIterable, Sendable {
    case sameAsLeft
    case quit

    init(storedValue: String?) {
        switch storedValue {
        case Self.quit.rawValue, "退出应用": self = .quit
        default: self = .sameAsLeft
        }
    }
}

nonisolated enum MenuBarMouseButton: Sendable {
    case left
    case right
}

nonisolated enum MenuBarCommand: Sendable, Equatable {
    case togglePanel
    case terminate
}

nonisolated enum MenuBarInteraction {
    static func command(
        for button: MenuBarMouseButton,
        rightClickAction: MenuBarRightClickAction
    ) -> MenuBarCommand {
        button == .right && rightClickAction == .quit ? .terminate : .togglePanel
    }
}

/// The persistence names owned by MacStatus. Callers use these semantic names rather
/// than duplicating storage strings, while AppPreferences owns migration and reset.
nonisolated enum AppPreferenceKeys {
    static let activeUpdateInterval = "activeUpdateInterval"
    static let autoHidePanel = "autoHidePanel"
    static let batteryChargingBorderStyle = "batteryChargingBorderStyle"
    static let batteryChargingIndicator = "batteryChargingIndicator"
    static let batteryChargingIndicatorMigrated = "batteryChargingIndicatorMigrated"
    static let batteryFillStyle = "batteryFillStyle"
    static let batteryInnerContent = "batteryInnerContent"
    static let batteryInnerContentV2Migrated = "batteryInnerContentV2Migrated"
    static let batteryLayout = "batteryLayout"
    static let batteryManFaceStyle = "batteryManFaceStyle"
    static let batteryManHandAction = "batteryManHandAction"
    static let batteryManHandActionSide = "batteryManHandActionSide"
    static let batteryManLegLength = "batteryManLegLength"
    static let batteryManShowAccessory = "batteryManShowAccessory"
    static let batteryManShowArms = "batteryManShowArms"
    static let batteryManShowFace = "batteryManShowFace"
    static let batteryManShowPosture = "batteryManShowPosture"
    static let batteryShellStyle = "batteryShellStyle"
    static let enablePanelAnimations = "enablePanelAnimations"
    static let hasMigratedToV2 = "hasMigratedToV2"
    static let iconLowPowerColor = "iconLowPowerColor"
    static let isPanelEditing = "isPanelEditing"
    static let mainIconGroupSpacing = "mainIconGroupSpacing"
    static let menuBarPowerStyle = "menuBarPowerStyle"
    static let menuItemSpacing = "menuItemSpacing"
    static let menuRightClickAction = "menuRightClickAction"
    static let menuUpdateInterval = "menuUpdateInterval"
    static let panelTheme = "panelTheme"
    static let panelWidgetOrder = "panelWidgetOrder"
    static let powerFlowSankeyAnimated = "powerFlowSankeyAnimated"
    static let powerFlowSankeyShowValues = "powerFlowSankeyShowValues"
    static let powerFlowSankeyStyle = "powerFlowSankeyStyle"
    static let powerFlowStyle = "powerFlowStyle"
    static let powerFlowThreeStage = "powerFlowThreeStage"
    static let powerFlowTwinAnimated = "powerFlowTwinAnimated"
    static let previewIsDark = "previewIsDark"
    static let showAdapterCurrent = "showAdapterCurrent"
    static let showAdapterPower = "showAdapterPower"
    static let showAdapterVoltage = "showAdapterVoltage"
    static let showAlDenteCalibration = "showAlDenteCalibration"
    static let showAlDenteFull = "showAlDenteFull"
    static let showAlDenteOverheat = "showAlDenteOverheat"
    static let showAlDenteSailing = "showAlDenteSailing"
    static let showAmperage = "showAmperage"
    static let showChargingStatus = "showChargingStatus"
    static let showCycles = "showCycles"
    static let showMacOSCapacity = "showMacOSCapacity"
    static let showMacOSCondition = "showMacOSCondition"
    static let showMaxCapacity = "showMaxCapacity"
    static let showPercentage = "showPercentage"
    static let showSystemLoad = "showSystemLoad"
    static let showTemperature = "showTemperature"
    static let showTimeRemaining = "showTimeRemaining"
    static let showVoltage = "showVoltage"
    static let showWattage = "showWattage"
    static let sysMonShowCPU = "sysMonShowCPU"
    static let sysMonShowGPU = "sysMonShowGPU"
    static let sysMonShowNetwork = "sysMonShowNetwork"
    static let sysMonShowDisk = "sysMonShowDisk"
    static let sysMonShowTemperature = "sysMonShowTemperature"
    static let sysMonShowDetails = "sysMonShowDetails"
    static let sysMonShowHeatmaps = "sysMonShowHeatmaps"
    static let sysMonMemoryLayout = "sysMonMemoryLayout"
    static let sysMonMemoryHeight = "sysMonMemoryHeight"
    static let sysMonComputeHeight = "sysMonComputeHeight"
    static let sysMonIOHeight = "sysMonIOHeight"
    static let sysMonSectionSpacing = "sysMonSectionSpacing"
    static let sysMonLayoutMigrated = "sysMonLayoutMigrated"
    static let sysMonBlockInterval = "sysMonBlockInterval"
    static let sysMonChartPixelSize = "sysMonChartPixelSize"
    static let sysMonHeatmapSize = "sysMonHeatmapSize"
    static let sysMonPixelDensity = "sysMonPixelDensity"
    static let sysMonPixelGap = "sysMonPixelGap"
    static let sysMonPixelShape = "sysMonPixelShape"
    static let sysMonShowCompute = "sysMonShowCompute"
    static let sysMonShowMemory = "sysMonShowMemory"
    static let sysMonShowNetDisk = "sysMonShowNetDisk"
    static let sysMonSymmetricGraph = "sysMonSymmetricGraph"
    static let twinCableStyle = "twinCableStyle"
    static let twinDeviceType = "twinDeviceType"
    static let twinMacColor = "twinMacColor"
}

nonisolated enum AppPreferences {
    static let defaultWidgetOrder = ["powerFlow", "batterySpecs", "batteryHealth", "systemMonitor"]

    private static var registeredDefaults: [String: Any] { [
        AppPreferenceKeys.activeUpdateInterval: 1.0,
        AppPreferenceKeys.autoHidePanel: true,
        AppPreferenceKeys.batteryChargingBorderStyle: "sharp",
        AppPreferenceKeys.batteryChargingIndicator: "bolt",
        AppPreferenceKeys.batteryChargingIndicatorMigrated: false,
        AppPreferenceKeys.batteryFillStyle: "monochrome",
        AppPreferenceKeys.batteryInnerContent: "none",
        AppPreferenceKeys.batteryInnerContentV2Migrated: false,
        AppPreferenceKeys.batteryLayout: "left",
        AppPreferenceKeys.batteryManFaceStyle: "solid",
        AppPreferenceKeys.batteryManHandAction: "none",
        AppPreferenceKeys.batteryManHandActionSide: "right",
        AppPreferenceKeys.batteryManLegLength: "normal",
        AppPreferenceKeys.batteryManShowAccessory: false,
        AppPreferenceKeys.batteryManShowArms: false,
        AppPreferenceKeys.batteryManShowFace: false,
        AppPreferenceKeys.batteryManShowPosture: false,
        AppPreferenceKeys.batteryShellStyle: "native",
        AppPreferenceKeys.enablePanelAnimations: true,
        AppPreferenceKeys.hasMigratedToV2: false,
        AppPreferenceKeys.iconLowPowerColor: false,
        AppPreferenceKeys.isPanelEditing: false,
        AppPreferenceKeys.mainIconGroupSpacing: 4.0,
        AppPreferenceKeys.menuBarPowerStyle: "graphic",
        AppPreferenceKeys.menuItemSpacing: 4.0,
        AppPreferenceKeys.menuRightClickAction: MenuBarRightClickAction.sameAsLeft.rawValue,
        AppPreferenceKeys.menuUpdateInterval: 10.0,
        AppPreferenceKeys.panelTheme: "system",
        AppPreferenceKeys.panelWidgetOrder: defaultWidgetOrder,
        AppPreferenceKeys.powerFlowSankeyAnimated: true,
        AppPreferenceKeys.powerFlowSankeyShowValues: true,
        AppPreferenceKeys.powerFlowSankeyStyle: "watchband",
        AppPreferenceKeys.powerFlowStyle: "cards",
        AppPreferenceKeys.powerFlowThreeStage: false,
        AppPreferenceKeys.powerFlowTwinAnimated: true,
        AppPreferenceKeys.previewIsDark: true,
        AppPreferenceKeys.showAdapterCurrent: false,
        AppPreferenceKeys.showAdapterPower: false,
        AppPreferenceKeys.showAdapterVoltage: false,
        AppPreferenceKeys.showAlDenteCalibration: false,
        AppPreferenceKeys.showAlDenteFull: false,
        AppPreferenceKeys.showAlDenteOverheat: false,
        AppPreferenceKeys.showAlDenteSailing: false,
        AppPreferenceKeys.showAmperage: false,
        AppPreferenceKeys.showChargingStatus: false,
        AppPreferenceKeys.showCycles: false,
        AppPreferenceKeys.showMacOSCapacity: false,
        AppPreferenceKeys.showMacOSCondition: false,
        AppPreferenceKeys.showMaxCapacity: false,
        AppPreferenceKeys.showPercentage: true,
        AppPreferenceKeys.showSystemLoad: false,
        AppPreferenceKeys.showTemperature: false,
        AppPreferenceKeys.showTimeRemaining: false,
        AppPreferenceKeys.showVoltage: false,
        AppPreferenceKeys.showWattage: false,
        AppPreferenceKeys.sysMonShowCPU: true,
        AppPreferenceKeys.sysMonShowGPU: true,
        AppPreferenceKeys.sysMonShowNetwork: true,
        AppPreferenceKeys.sysMonShowDisk: true,
        AppPreferenceKeys.sysMonShowTemperature: true,
        AppPreferenceKeys.sysMonShowDetails: true,
        AppPreferenceKeys.sysMonShowHeatmaps: true,
        AppPreferenceKeys.sysMonMemoryLayout: 0,
        AppPreferenceKeys.sysMonMemoryHeight: 64.0,
        AppPreferenceKeys.sysMonComputeHeight: 52.0,
        AppPreferenceKeys.sysMonIOHeight: 52.0,
        AppPreferenceKeys.sysMonSectionSpacing: 12.0,
        AppPreferenceKeys.sysMonLayoutMigrated: false,
        AppPreferenceKeys.sysMonBlockInterval: 0,
        AppPreferenceKeys.sysMonChartPixelSize: 5.0,
        AppPreferenceKeys.sysMonHeatmapSize: 8.0,
        AppPreferenceKeys.sysMonPixelDensity: 1.0,
        AppPreferenceKeys.sysMonPixelGap: 1.5,
        AppPreferenceKeys.sysMonPixelShape: 0,
        AppPreferenceKeys.sysMonShowCompute: true,
        AppPreferenceKeys.sysMonShowMemory: true,
        AppPreferenceKeys.sysMonShowNetDisk: true,
        AppPreferenceKeys.sysMonSymmetricGraph: false,
        AppPreferenceKeys.twinCableStyle: "p",
        AppPreferenceKeys.twinDeviceType: "mbp",
        AppPreferenceKeys.twinMacColor: "silver",
    ] }

    static let menuBarKeys: Set<String> = [
        AppPreferenceKeys.batteryChargingBorderStyle,
        AppPreferenceKeys.batteryChargingIndicator,
        AppPreferenceKeys.batteryChargingIndicatorMigrated,
        AppPreferenceKeys.batteryFillStyle,
        AppPreferenceKeys.batteryInnerContent,
        AppPreferenceKeys.batteryInnerContentV2Migrated,
        AppPreferenceKeys.batteryLayout,
        AppPreferenceKeys.batteryManFaceStyle,
        AppPreferenceKeys.batteryManHandAction,
        AppPreferenceKeys.batteryManHandActionSide,
        AppPreferenceKeys.batteryManLegLength,
        AppPreferenceKeys.batteryManShowAccessory,
        AppPreferenceKeys.batteryManShowArms,
        AppPreferenceKeys.batteryManShowFace,
        AppPreferenceKeys.batteryManShowPosture,
        AppPreferenceKeys.batteryShellStyle,
        AppPreferenceKeys.iconLowPowerColor,
        AppPreferenceKeys.mainIconGroupSpacing,
        AppPreferenceKeys.menuBarPowerStyle,
        AppPreferenceKeys.menuItemSpacing,
        AppPreferenceKeys.menuRightClickAction,
        AppPreferenceKeys.menuUpdateInterval,
        AppPreferenceKeys.previewIsDark,
        AppPreferenceKeys.showAdapterCurrent,
        AppPreferenceKeys.showAdapterPower,
        AppPreferenceKeys.showAdapterVoltage,
        AppPreferenceKeys.showAlDenteCalibration,
        AppPreferenceKeys.showAlDenteFull,
        AppPreferenceKeys.showAlDenteOverheat,
        AppPreferenceKeys.showAlDenteSailing,
        AppPreferenceKeys.showAmperage,
        AppPreferenceKeys.showChargingStatus,
        AppPreferenceKeys.showCycles,
        AppPreferenceKeys.showMacOSCapacity,
        AppPreferenceKeys.showMacOSCondition,
        AppPreferenceKeys.showMaxCapacity,
        AppPreferenceKeys.showPercentage,
        AppPreferenceKeys.showSystemLoad,
        AppPreferenceKeys.showTemperature,
        AppPreferenceKeys.showTimeRemaining,
        AppPreferenceKeys.showVoltage,
        AppPreferenceKeys.showWattage,
    ]

    static func migrate(_ defaults: UserDefaults = .standard) {
        let stored = defaults.string(forKey: AppPreferenceKeys.menuRightClickAction)
        if stored == "同左击" || stored == "退出应用" {
            defaults.set(MenuBarRightClickAction(storedValue: stored).rawValue,
                         forKey: AppPreferenceKeys.menuRightClickAction)
        }
        guard !defaults.bool(forKey: AppPreferenceKeys.sysMonLayoutMigrated) else { return }
        for (legacy, children) in [
            (AppPreferenceKeys.sysMonShowCompute, [AppPreferenceKeys.sysMonShowCPU, AppPreferenceKeys.sysMonShowGPU]),
            (AppPreferenceKeys.sysMonShowNetDisk, [AppPreferenceKeys.sysMonShowNetwork, AppPreferenceKeys.sysMonShowDisk])
        ] {
            let visible = defaults.object(forKey: legacy) as? Bool ?? true
            for key in children where defaults.object(forKey: key) == nil || !visible {
                defaults.set(visible, forKey: key)
            }
        }
        // Convert the old implicit height once. Pixel size is independent afterwards.
        let size = MonitorPixelGrid.bounded(defaults.object(forKey: AppPreferenceKeys.sysMonChartPixelSize) as? Double ?? 5, in: 2...10, fallback: 5)
        let gap = MonitorPixelGrid.bounded(defaults.object(forKey: AppPreferenceKeys.sysMonPixelGap) as? Double ?? 1.5, in: 0...4, fallback: 1.5)
        let density = MonitorPixelGrid.bounded(defaults.object(forKey: AppPreferenceKeys.sysMonPixelDensity) as? Double ?? 1, in: 0.5...1.5, fallback: 1)
        let groups = defaults.integer(forKey: AppPreferenceKeys.sysMonBlockInterval)
        func oldHeight(rows: Double) -> Double {
            let count = Int(ceil(rows * density))
            let groupedGap = groups == 1 || groups == 3 ? Double((count - 1) / 4) * gap : 0
            return Double(count) * size + Double(count - 1) * gap + groupedGap
        }
        if size != 5 || gap != 1.5 || density != 1 || groups != 0 {
            defaults.set(min(160, max(24, oldHeight(rows: 8))), forKey: AppPreferenceKeys.sysMonComputeHeight)
            defaults.set(min(200, max(24, oldHeight(rows: 8))), forKey: AppPreferenceKeys.sysMonMemoryHeight)
            defaults.set(min(120, max(32, oldHeight(rows: 4) * 2 + 6)), forKey: AppPreferenceKeys.sysMonIOHeight)
        }
        defaults.set(true, forKey: AppPreferenceKeys.sysMonLayoutMigrated)
    }

    static var systemMonitorKeys: Set<String> {
        Set(registeredDefaults.keys.filter { $0.hasPrefix("sysMon") })
    }

    static func resetSystemMonitor(_ defaults: UserDefaults = .standard) {
        for key in systemMonitorKeys { defaults.removeObject(forKey: key) }
        // A reset uses the new defaults, not another conversion of the legacy layout.
        defaults.set(true, forKey: AppPreferenceKeys.sysMonLayoutMigrated)
    }

    static func registerDefaults(_ defaults: UserDefaults = .standard) {
        defaults.register(defaults: registeredDefaults)
    }

    static func rightClickAction(_ defaults: UserDefaults = .standard) -> MenuBarRightClickAction {
        MenuBarRightClickAction(storedValue: defaults.string(forKey: AppPreferenceKeys.menuRightClickAction))
    }

    static func resetMenuBar(_ defaults: UserDefaults = .standard) {
        for key in menuBarKeys {
            defaults.removeObject(forKey: key)
        }
    }
}

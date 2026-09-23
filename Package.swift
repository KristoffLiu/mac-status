// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MacStatusCore",
    platforms: [.macOS(.v26)],
    products: [.library(name: "MacStatusCore", targets: ["MacStatusCore"])],
    targets: [
        .target(name: "MacStatusCore", path: "MacStatus/MacStatus", exclude: [
            "UI", "Resources", "Assets.xcassets", "Localizable.xcstrings", "AppDelegate.swift", "MacStatusApp.swift", "StatusViewModel.swift",
            "Models/MenuBarPowerStyle.swift", "Services/AppEnergyMonitor.swift", "Services/BatteryService.swift",
            "Services/EnergyEfficiencyManager.swift", "Services/HighPowerAppsService.swift", "Services/SMCService.swift",
            "Services/SystemMonitorService.swift", "Services/XPCCoordinator.swift", "Services/PowerSampler.swift", "Services/SystemMetricsCollector.swift",
            "Services/StatusSnapshotCoordinator.swift"
        ], sources: ["Models/SystemMonitorLayout.swift", "Models/AppPreferences.swift", "Models/MonotonicThrottle.swift", "Models/StatusSnapshot.swift", "Models/SankeySupplyLayout.swift", "Models/BatteryData.swift", "Models/BatteryPowerTrend.swift", "Models/PowerTopology.swift", "Models/PowerSensors.swift", "Services/PowerCalculationService.swift", "Services/PowerPresentationReducer.swift", "Models/SamplingPolicy.swift", "Models/SMCValueDecoder.swift", "Models/ProcessOutputParser.swift", "Services/CommandRunner.swift", "Services/LoginItemService.swift"]),
        .testTarget(name: "MacStatusCoreTests", dependencies: ["MacStatusCore"])
    ]
)

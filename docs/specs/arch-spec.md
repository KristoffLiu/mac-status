# MacStatus 架构设计规范 (Architecture Specification)

该文档定义了 MacStatus 应用的底层架构与服务划分，专注为 Apple Silicon (M-series) 提供极致的功耗监测。

## 1. 核心架构模式 (Core Architecture Pattern - M-series Optimized)

采用 **MVVM-C** 架构，针对 Apple Silicon 的统一功率域 (Power Domains) 进行模块化设计。
核心分为 **传感器采集层 (Sensor Capture)**、**功率引擎层 (Power Engine v2)** 与 **声明式视图层 (SwiftUI Views)**。

## 2. 传感器采集层 (Sensor Capture Layer)

- **`BatteryService.swift`**: 
  负责与 `IOKit` (`AppleSmartBattery`) 通信，获取电量、电压、健康度等基础信息。
- **`MSeriesPowerService.swift` (New)**: 
  核心功率捕获引擎，负责：
  - **IOReport 订阅**: 调用 `libIOReport.dylib` 私有 API 订阅 CPU、GPU 与 ANE (神经引擎) 的微秒级能量计数。
  - **PMU 传感器**: 通过 `IOConnectCallStructMethod` 访问 Apple PMU 传感器，获取插电旁路模式下的实时输出功率。

## 3. 计算与控制层 (Calculation & Control Layer)

- **`PowerCalculationService.swift`**:
  整合 `BatteryService` 与 `MSeriesPowerService` 的数据。
  - **能量拓扑判断**: 实时更新拓扑状态 (Topology A/B/C)。
  - **数据平滑**: 实现 2 秒滑动窗口平滑 (Moving Average)，防止 UI 读数跳变过于剧烈。
- **`EnergyEfficiencyManager.swift` (极致能控)**:
  - **按需采样**: 当且仅当面板处于 `Active` (打开) 状态时开启 IOReport 高频订阅；后台时降频至低功耗模式（1% 以下 CPU 占用）。

## 4. UI 架构与模块化 (UI Composition)

- **`PanelModuleManager.swift`**:
  解耦各个显示模块（Sankey、详情网格、高功耗雷达）。
- **`MenuBarCustomizationManager.swift`**:
  控制菜单栏展示逻辑（图标、百分比、瓦数）。

## 5. 展现层 (View Layer)

- **`SankeyPowerFlowView.swift`**: 
  使用 `Canvas` 与 `TimelineView` 实现 60fps 的液态能量流动动画。
- **`VisualEffectBackground.swift`**: 
  包装 `NSVisualEffectView` 实现 Liquid Glass (毛玻璃) 视觉效果。
- **`HighPowerAppsModule.swift`**:
  通过后台 `top` 指令抓取能耗最高的应用列表。

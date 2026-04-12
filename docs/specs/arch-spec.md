# MacStatus 架构设计规范 (Architecture Specification)

该文档定义了 MacStatus 应用的底层架构与服务划分，确保应用在提供复杂桑基图动画的同时保持绝佳性能（零功耗）。

## 1. 核心架构模式 (Core Architecture Pattern)

推荐采用 **MVVM-C** 或轻量化的单向数据流 (Unidirectional Data Flow) 架构。
为保证模块级别的解耦，系统将拆分为 **数据服务层 (Data Services)**、**计算与控制层 (Calculation & Control Layer)**、**UI 分发层 (UI Composition)** 与 **展现层 (View)**。

## 2. 数据服务层 (Data Services)

- **`BatteryService.swift`**: 
  负责与 底层 `IOKit` (`AppleSmartBattery`) 进行通信，抽象为 Swift 的异步接口或 Combine Publisher，不再直接向 UI 暴露原始字典。
- **`AdapterService.swift`** (或将其并入电源服务): 
  监听交流适配器连接状态及其设计的额定瓦数。

## 3. 计算与控制层 (Calculation & Control Layer)

- **`PowerCalculationService.swift`**:
  订阅底层数据，根据电量流入流出，判断此时应用处于哪种**能量拓扑**（如 Topology A/B），算出适配器输出功率、系统总消耗功率。统一处理计算后再通过 ViewModel 暴露。
- **`EnergyEfficiencyManager.swift`** (极致能控):
  - **规则**: 在面板置于后台时，动画 Timer 与频繁的 CPU 计算必须终止；当且仅当 `isPresented` (面板打开) 时，启动高频刷新。
  - **实现**: 拦截或管理全局轮询定时器，根据 UI 状态动态改变派发频率。

## 4. UI 架构与模块化 (UI Composition & Modularity)

- **`PanelModuleManager.swift`**:
  管理面板内部区块显示（例如 Sankey 可视化区块、数值详情区块），允许后续加入新的显示内容而不侵入主容器代码。
- **`MenuBarCustomizationManager.swift`**:
  与 `AppStorage` (UserDefaults) 交互，控制用户想要在菜单栏展示的是图标、数字百分比还是功率。

## 5. 声明式 UI 层 (SwiftUI View)

- **`SankeyPowerFlowView.swift`**: 使用 Path 与 Timer/PhaseAnimator 的重绘制，依赖注入了当前能量拓扑状态。
- **`VisualEffectBackground.swift`**: 基于 `NSViewRepresentable` 对 `NSVisualEffectView` 包装，支撑整体毛玻璃视觉体系。

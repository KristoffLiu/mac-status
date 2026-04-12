# MacStatus 开发与设计规划 (Liquid Glass & Sankey 视觉版)

本文档记录了目前 MacStatus 菜单栏应用的状态，以及接下来需要完成的体系化功能开发与全面 UI 升级计划。重点突出了基于 macOS 大圆角与桑基图能量流的可视化重构。

## 1. 背景与已完成工作 (Background & Current State)

我们正在开发一款使用 SwiftUI 编写的 macOS 菜单栏状态应用 (MenuBar App)，用于实时显示电池与电源状态。
目前已实现的基础功能：
1. **纯菜单栏应用架构**: 使用 `SwiftUI` 的 `MenuBarExtra` 实现，为 Accessory 模式应用。
2. **底层硬件数据读取**: `StatusViewModel` 实现了对 `AppleSmartBattery` 和 `AdapterDetails` 的读取，并能暴露准确的实时电压、电流、设计/当前容量、循环次数及适配器瓦数。
3. **精准状态推断**: 修复了“满电插电显示电流为 0”的问题，能够准确分辨 Charging (充电)、Discharging (放电)、Adapter Power (适配器直接供电) 以及 Idle 处理。

## 2. 目标界面设计美学 (Target UI & Visual Aesthetics)

根据设定的目标，我们将参考 **MacOS 26 Liquid Glass** 及类似 **AlDente Pro** 的高级动态可视化形式来全面升级 App。设计语言将包含：

1. **桑基图 (Sankey Diagram) 能量流可视化**:
   - 作为界面的核心，采用带有流线感和渐变色（科技感的蓝色、绿色渐变）的“水流”能量带来展示功率流向。
   - 动态表现出电源适配器的总输入功率，是如何被分配给 **系统运行消耗** 与 **电池充电** 两端的。
2. **圆角设计 (Squircles)**:
   - 全面引入苹果标志性的连续圆角 (Continuous Curves) 元素。所有的卡片、按钮和进度条均使用大比例平滑圆角。
3. **暗黑模式 (Dark Mode) 与层级感**:
   - 采用具有深度感和轻微阴影的深灰色背景系（拟物化的层深），通过背景与高光区分出明确操作层级。
4. **液态毛玻璃透明 (Liquid Glass / Vibrancy)**:
   - 背景使用具有模糊透视感的 `VisualEffectView` 或材质层 (`.regularMaterial` / `.thinMaterial`)，营造悬浮于菜单栏之下的精致 Popover 气泡框观感。
5. **流体微动画 (Fluid & Movement)**:
   - 取代静态的数字变化，通过能量在曲线管路中的动态流动，打造生动直观的视觉反馈呈现。

## 3. 架构升级方案 (Upgrade Architecture)

- **UI 层划分**:
  - `VisualEffectBackground`: 负责底层真实的毛玻璃和发光效果。
  - `SankeyPowerFlowView`: 纯渲染图形的组件，利用 SwiftUI 的 `Path`、`Shape` 和 `LinearGradient` 配合时间动画，渲染能量流动。
  - `SensorsDataView`: 传统的精细排印数字信息展示（采用现代字体：如SF Pro Rounded）。
  
- **逻辑层重构**:
  - 剥离原混合在 ViewModel 里的读取逻辑到专用的 `BatteryService` 和 `PowerCalculationService` 中，专门处理复杂的物理公式（如`系统消耗 = 适配器输入 - 电池充入`）。

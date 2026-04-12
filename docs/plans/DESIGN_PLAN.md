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

1. **桑基图 (Sankey Diagram) 动态能量流模型**:
   - 作为界面的核心，采用带有流线感和渐变色的能量带（如充电时使用绿色，放电使用蓝色或灰色）展示真实的物理能量拓扑。
   - 具备**双向动态拓扑识别**：
     - **状态 A (充电中)**：电源适配器 (左) -> 电池充电 (右下) & 系统消耗 (右上)。
     - **状态 B (供电不足/电池放电)**：电源适配器 (左上) + 电池放电 (左下) -> 系统消耗 (右)。
   - 包含具体的实时瓦数 (W) 标注，呈现严谨的能量守恒数据。
2. **圆角设计 (Squircles)**:
   - 全面引入苹果标志性的连续圆角 (Continuous Curves) 元素。所有的卡片、按钮和进度条均使用大比例平滑圆角。
3. **暗黑模式 (Dark Mode) 与层级感**:
   - 采用具有深度感和轻微阴影的深灰色背景系（拟物化的层深），通过背景与高光区分出明确操作层级。
4. **液态毛玻璃透明 (Liquid Glass / Vibrancy)**:
   - 背景使用具有模糊透视感的 `VisualEffectView` 或材质层 (`.regularMaterial` / `.thinMaterial`)，营造悬浮于菜单栏之下的精致 Popover 气泡框观感。
5. **流体微动画 (Fluid & Movement)**:
   - 取代静态的数字变化，通过能量在曲线管路中的动态流动，打造生动直观的视觉反馈呈现。

## 3. 架构升级方案 (Upgrade Architecture)

- **UI 层划分与模块化开发 (Modular UI Architecture)**:
   - `VisualEffectBackground`: 负责底层真实的毛玻璃和发光效果。
   - `MenuBarCustomization`: 状态栏图标与文本展示层，支持高度自定义（如：图标+百分比、仅图标、图标+剩余时间等组合）。
   - `PanelModuleSystem`: 弹出面板将采用**模块化 (Widget-like)** 的架构。不仅支持桑基图 (`SankeyPowerFlowView`)，未来还能横向扩展加入其他系统监视模块（如 CPU、内存、网络），并支持用户在偏好设置中显隐和重排。
   
- **逻辑层重构与极致性能优化 (Zero-Drain Performance)**:
   - **数据剥离**：将原混合在 ViewModel 里的读取逻辑剥离到 `BatteryService` 和 `PowerCalculationService` 中。
   - **极致能效 (Energy Efficiency)**：严格保证应用处于“零耗电”最佳实践。UI 流体微动画仅在面板呼出时激活（借助 `isPresented` 或 `onAppear`），后台只以极低频率维护状态栏数值。避免 CPU 唤醒，防止 App 自身成为耗电大户。

## 4. 开发阶段规划 (Implementation Phases)

### 阶段一：数据与架构解耦 (Data & Architecture Refactoring)
- **目标**: 将杂糅在视图模型中的低级系统调用分离，确保在重构 UI 时底层数据的准确和稳定。
- **任务**: 抽离 `BatteryService` 和 `AdapterService`，并在 ViewModel 层提供稳定的基于合并流的功率数据输出（如明确算出：当前系统功耗是 X 瓦）。

### 阶段二：底层视觉组件构建 (Visual Foundations)
- **目标**: 搭建全局符合 "Liquid Glass" 的基本外观。
- **任务**: 编写全局透视模糊背景组件。制定颜色常量（代表充满、放电、充电与安全区的颜色），以及统一定义大圆角常数 (Squircles Radius)。

### 阶段三：Sankey 动态能量流核心研发 (Sankey Flow Core)
- **目标**: 攻克本项目最难的部分——贝塞尔曲线动画能量图。
- **任务**: 
  - 根据电池状态和功率比例，计算曲线路径 `Path`。
  - 使用 SwiftUI 动画实现渐变流动的 `Timer` 更新或 `PhaseAnimator` 驱动粒子的能量流感。
  - 将适配器状态、电池充放电状态和系统消耗点用流向完美连接展现。

### 阶段四：数字面板与细节抛光 (Typography & Polish)
- **目标**: 完成外围 UI 展示与交互。
- **任务**: 统一采用现代化字距设计的数值面板（SF Pro Rounded），补充适配器种类显示、充放电预估时间显示，并添加应用自动启动与偏好设置的支持。

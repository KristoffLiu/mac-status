# MacStatus 开发与设计规划 (Liquid Glass & M-Series Power 版)

本文档记录了 MacStatus 菜单栏应用的状态，以及接下来针对 Apple Silicon (M-series) 优化的体系化功能开发计划。

## 1. 背景与核心路线 (Background & Strategy)

我们将应用定位为 **Apple Silicon 专场极客工具**。不再考虑 Intel 兼容性，从而利用 M 芯片统一的 PMU (Power Management Unit) 与 IOReport 框架实现极致的精度。

### 已完成工作：
- 基础 MenuBarExtra 架构与 IOKit 电池数据读取。
- 桑基图 (Sankey Diagram) 的初步可视化（支持拓扑 A/B）。
- 适配 macOS 26 Liquid Glass 的高透毛玻璃视觉容器。
- 高功耗应用雷达 (Energy Impact Radar)。

## 2. 目标：Power Engine v2 (M-Series Optimized)

为了对标 AlDente Pro 等专业工具，我们将实施“功率引擎 v2”计划：

### 1. 真实功耗追踪 (Real-time Wattage)
- **挑战**：标准 IOKit 在旁路模式（AC Connected, Battery Full）下无法提供系统总瓦数。
- **解决方案**：引入 `libIOReport.dylib` 订阅。直接监听：
  - `CPU Power Domain` (各核心能耗)
  - `GPU Power Domain`
  - `ANE (Apple Neural Engine) Power`
  - `DRAM / System Total`
- **结果**：在插电且不充电的情况下，准确显示主板真实消耗（如 25.5W）。

### 2. 桑基图 (Sankey Diagram) 深度进化
- **数据驱动**：桑基图的粗细与流速将完全由 `IOReport` 提供的实时瓦数驱动。
- **拓扑识别**：
  - **Bypass 模式**：适配器 -> 系统（电池分支流量为 0W，但系统分支显示真实功耗）。
  - **混合模式**：电池 + 适配器同时供电或适配器同时供电与充电。

## 3. 架构升级：M-Series Sensor Capture

- **`MSeriesPowerService`**: 整合私有 `IOReport` API 和 `HID` 传感器。
- **`EnergyEfficiencyManager`**: 
  - **打开面板时**：IOReport 采样频率 500ms，保证数值波动顺滑。
  - **关闭面板时**：彻底销毁采样器，防止 App 自身产生 Energy Impact。

## 4. 后续开发阶段 (Upcoming Phases)

### 阶段一：功率引擎 v2 开发 (当前重点)
- 编写 `libIOReport` 的 Swift 桥接层。
- 实现 component-level (CPU/GPU) 的功率抓取。

### 阶段二：Sankey 视觉抛光
- 根据真实功率值对流动动画进行非线性缩放（10W 与 100W 的粗细不再只是简单线性）。
- 增加流体粒子特效，增强“电能流动”的质感。

### 阶段三：高级控制功能 (可选)
- 调研通过 `BCLM` 键执行 Apple Silicon 上的物理限电（80% 限制）。这可能需要安装特权 Helper Tool。

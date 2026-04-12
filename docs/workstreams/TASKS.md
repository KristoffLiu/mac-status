# MacStatus 待办事项与发版计划 (TASKS)

执行基于 "macOS 26 liquid glass" 与 "AlDente Pro" 风格的可视化设计重构路线，并引入**双向状态拓扑**与**极致零功耗**策略。

## 第一阶段：服务层抽离与极客数据处理 (Data & Efficiency Core)
- [x] 抽离 `BatteryService` 与 `PowerCalculationService`。
- [x] 解析双向**能量拓扑架构**:
  - **拓扑 A (充电/电源盈余)**：适配器 -> 电池充入 + 系统消耗。
  - **拓扑 B (耗电/电源不足)**：适配器 + 电池放出 -> 系统消耗。
- [x] 引入 `EnergyEfficiencyManager`，在面板未通过 `MenuBar` 交互展开前，令所有内部 Timer 处于低频沉睡状态，绝不抢占 CPU。

## 第二阶段：UI 基础与液态视觉准备 (Liquid Glass Base)
- [x] 引入原生的或高度拟真的毛玻璃材质 (`NSVisualEffectView` 或 SwiftUI 的 Materials) 作为 App 的基底。
- [x] 建立 `PanelModuleManager` 架构，使弹出面板结构完全解耦并且可以上下重排。
- [x] 定义基础颜色字典 (绿/充电、蓝/耗电、黄橙/供电源)，强制推行 Apple 连续大圆角 (Squircles Radius > 16pt)。

## 第三阶段：核心流体动画 - 动态桑基图计算 (Sankey Flow Engine)
- [x] 编写核心动画模块 `SankeyPowerFlowView`，利用 SwiftUI 的 `Path` (贝塞尔曲线 `.quadCurve`) 串联绘制能量分流图。
- [x] 将底层算出的 `SystemPower`, `BatteryPower`, `AdapterPower` 与节点宽度或数值绑定，做到数据改变曲线立刻反映。
- [x] 根据用户诉求：让流动的速度 (如 `dashPhase` 或粒子位移速度) 与绝对的实心功率大小 (`wattage`) 成正比——充电越猛，流速越疯！

## 第四阶段：状态展示打磨与定制支持 (Typography & Customization)
- [x] 统一数字面板渲染风格，应用现代科技感字体 `SF Pro Rounded` 且配置 `monospacedDigit` 防抖。
- [x] 补齐 `MenuBar` 图标的高级自定义选项，通过 `AppStorage` 允许用户自由组合（文字，图标，百分比等）。
- [x] 构建电池详细数据展示块（循环次数、电压、健康度衰减卡片），作为下置的详情组件。

## 第五阶段：工程收尾与发布
- [ ] 实现 App 开机启动 (Launch at Login) 以满足常驻后台运行的核心需求。
- [ ] 完善主界面的 README.md，附上流速爆炸动态图与毛玻璃视效图。
- [ ] 归档打包，并运行严苛的 Activity Monitor 侦测验证，确保其 Energy Impact 指标在挂机时接近为 0。

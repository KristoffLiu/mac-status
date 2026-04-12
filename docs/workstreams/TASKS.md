# MacStatus 待办事项与发版计划 (TASKS)

执行基于 "macOS 26 liquid glass" 与 "AlDente Pro" 风格的可视化设计重构路线。

## 第一阶段：UI 层级与环境准备 (Liquid Glass & Squircles)
- [ ] 引入原生的或高度拟真的毛玻璃材质 (`NSVisualEffectView` 或 SwiftUI 的 Materials) 作为 App 的基底。
- [ ] 设定暗黑模式的基础色系体系 (Dark Mode, 阴影, 边框高亮反光层)。
- [ ] 构建底层采用大圆角 (Squircles) 的基础卡片 (Card) 容器组件。

## 第二阶段：核心数值与公式推演 (Power Distribution Logic)
- [ ] 在 `StatusViewModel` 中计算**总输入功率**（适配器）、**总消耗功率**（系统）和**电池功率池**（充/放电）。
- [ ] 处理公式推断逻辑：
  - **放电时**：系统耗电 = 电池放电功率
  - **充电时**：输入功率 = 适配器瓦数；流入电池 = 电池功率；系统耗电 = 输入功率 - 流入电池
  - **旁路供电时(Adapter Power)**：系统耗电 = 适配器瓦数；流入电池 = 0

## 第三阶段：核心视觉 - 桑基图 (Sankey Diagram Flow) 开发
- [ ] 编写自定义 SwiftUI `Shape` 绘制流畅的弯曲路径，建立“能量流动”的可视化管道。连接左侧的源头（Adapter/Battery）和右侧的耗电端（System/Battery）。
- [ ] 为不同流向的路径应用动态渐变色彩（例如：绿色代表充入电池，蓝色代表系统运行消耗）。
- [ ] 引入动画系统 (Animation / TimelineView)，在路径上绘制动态粒子或位移的虚线/渐变波纹，呈现“持续流动”的视觉感。

## 第四阶段：状态展示打磨 (Typography & Details)
- [ ] 引入具有现代感和科技感的圆体排版（如 `SF Pro Rounded` 和等宽数字 `monospacedDigit`）。
- [ ] 重新展示电压、电流、循环次数、健康度等细粒度数据，将其优雅地分布在 Sankey 节点容器中。
- [ ] 打磨交互体验（如：鼠标划过时的悬浮发光微缩放动画、数据的顺滑重绘）。

## 第五阶段：工程收尾与发布
- [ ] 实现 App 开机启动 (Launch at Login) 以满足常驻后台运行的核心需求。
- [ ] 完善主界面的 README.md（添加动图与架构说明）。
- [ ] 归档打包测试版本。

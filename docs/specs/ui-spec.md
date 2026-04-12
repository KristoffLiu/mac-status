# MacStatus 视觉与 UI 规范 (UI & Styling Specification)

我们的设计语言借鉴了 "macOS 26 Liquid Glass" 和行业标杆动态工具，强调材质透视感、大比例圆角与优雅的动画反馈。

## 1. 材质与背景 (Materials & Background)

- **Liquid Glass 效果**:
  - 全局容器必须依赖底层的 `VisualEffectBackground` 组件包裹。
  - 使用 macOS `.popover` 或 `.menu` 混色材质，开启并支持跨深色与浅色模式，但首推系统默认级别随动。在菜单栏展开后呈现无边框漂浮在空中的果冻视效。
  
## 2. 形状与排版 (Shapes & Typography)

- **大圆角 (Squircles)**:
  - 为了消除直角的锋利感，所有底层卡片模块 (Module Cards) 的 `cornerRadius` 应控制在 `16pt` 到 `24pt` 及以上的 Apple 连续曲线圆角风格 (`.continuous`)。
- **字体 (Typography)**:
  - 数字展现务必采用 `SF Pro Rounded`。
  - 对于快速跳动的功率/电流数字，开启 `.monospacedDigit()` 避免布局抖晃。

## 3. 颜色语义系统 (Semantic Color System)

- **颜色基调**:
  - **充电流向 (Charging In)**: 明快且富含能量的 **拟物绿 (Neon Green)** 或原生的安全绿色。
  - **放电流向 (Discharging / System Drain)**: 展现系统冷峻运行的 **能量蓝 (Electric Blue)** 或警告性的色调。
  - **适配器接入 (Adapter/Source)**: 可采用 **橙黄 (Amber/Orange)** 或纯净的高亮白光，以表示电力的源头。
  
## 4. 桑基图及流动动画规则 (Sankey Diagram & Animation logic)

- **曲线 (Curves)**: 
  通过 SwiftUI 贝塞尔路径 `.quadCurve` 取代生硬的折线，表现电流平滑无痕迹的流变。
- **粒子流与虚线位移 (Dash Flow)**: 
  使用 `stroke(style: StrokeStyle(dash: [x, y], dashPhase: offset))`。
- **动态速率**: 
  必须提供速率随动感，即功率越高，`dashPhase` 扣减/增加的频率越快（表现出真实世界水管中大流量奔流的物理观感）。

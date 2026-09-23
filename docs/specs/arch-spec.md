# MacStatus 当前架构

目标：Apple Silicon 笔记本、macOS 26。核心数据计算与 SwiftUI 展示分离。

## 采样与状态

- `PowerSampler` 在自己的串行队列维护电池缓存，每两秒最多读取一次 AppleSmartBattery；供电来源变化会绕过缓存。
- `BatteryService` 读取 IOKit；容量百分比与 mAh 分开，缺失电流不伪装成零电流。
- `SMCService` 在锁内访问连接和元数据缓存。仅按已知数据类型解码，拒绝 NaN、无穷和未知类型。连接异常后限频重试。
- `SystemMetricsCollector` 的历史计数与硬件引用由系统指标队列独占，网络与磁盘速率使用单调时间计算。
- `StatusSnapshotCoordinator` 独占每个 tick 的采集顺序，并发取得功率、系统指标与进程数据后输出一个带单调时间的 `StatusSnapshot`。
- `StatusViewModel` 和其他 ObservableObject 在 MainActor 发布数据；计算只消费 `StatusSnapshot`，不读取其他 module 的可变发布状态。
- 每次真实 AppleSmartBattery 读取带递增 acquisition ID 与单调时间；缓存复用不会伪装成新的状态观测。
- `PowerSampleAdapter` seam 有真机与 trace 回放两个 adapter，可用现场记录复现采集序列。

## 计算与展示

- `PowerCalculationService` 无硬件副作用，输入电池数据和 `PowerSensors`，输出 `PowerFlowData`。
- `PowerPresentationReducer` 在计算后统一确认展示方向，并由 `StatusViewModel` 独占；菜单栏和四种能量流视图消费同一个稳定结果。
- `BatteryPowerTrendAccumulator` 对最近一分钟的原始带符号功率做有界积分；它不创建额外计时器或硬件采样。
- 当前电源类型优先于旧适配器字典；额定功率不参与实时功率计算。
- 每项功率有实测、估算或不可用质量标记。不完整读数展示概要与 `—`，不渲染虚假的完整能量流。
- 电池控制器读数决定电池方向；适配器与系统 SMC 功率无法闭合时保留原始实测值，图中适配器分支按系统负载与已确认的电池方向计算。功率域差异仅保留在模型中供测试和诊断，不改变正常界面。
- 三段能耗是按 CPU/GPU 占用做的启发式分配，界面明确说明为估算。
- 桑基图、卡片、方块和设备视图共用输出模型；`WidgetManager` 持久化用户组件选择。
- `WidgetCatalog` 是面板 module 的唯一编译期目录；持久化值在读取时会过滤未知项并按原顺序去重。

## 能耗与生命周期

- `SamplingPolicy` 由面板可见性、启用组件、三段能耗选项、刷新间隔和睡眠状态决定。
- `EnergyEfficiencyManager` 统一 tick，默认后台 10 秒，仅保留菜单栏读数；用户可调整为 2–20 秒。
- 面板隐藏时停止系统详情与进程采集。三段能耗隐藏时不运行应用 CPU 排名。
- 进程采集使用可取消的 `CommandRunner`，无 shell 管道，有五秒超时；旧请求结果不会覆盖新状态。
- 桑基流和设备电缆动画仅在面板活动时运行，并尊重“减少动态效果”。
- `LoginItemService` 使用 `SMAppService.mainApp`，仅在用户切换时注册，并展示系统批准和失败状态。
- `AppPreferences` 集中拥有设置键、旧值迁移与菜单栏设置重置范围；运行路径不再散落裸字符串键。

## 测试与分发

`Package.swift` 将生产模型、快照与 trace 回放 adapter、计算、调度规则、偏好迁移、解析与进程运行器纳入 Swift Testing。
执行 `swift test`；应用仍由 Xcode scheme 构建。

当前没有特权 Helper / XPC target；旧 Helper 设计不属于本版本依赖。
站外发布、签名与公证见 [发布指南](../distribution.md)。

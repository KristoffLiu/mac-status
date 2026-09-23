# MacStatus 领域上下文

## Power acquisition snapshot（功率采集快照）

一次应用 tick 内获得的电池、SMC、系统指标与进程数据的值快照。`StatusSnapshotCoordinator` 负责采集顺序和时间信息；计算与展示只能消费快照，不直接读取其他 module 的可变状态。

## Power sample adapter（功率样本适配器）

向功率采集快照提供电池与传感器读数。生产环境使用真机 adapter，测试与诊断使用 trace 回放 adapter；两者经过同一个 seam。

## Sampling policy（采样策略）

由面板可见性、睡眠状态、刷新间隔、已启用面板 module 和三段能耗设置组成的不可变值。策略决定一个 tick 需要采集哪些数据。

## Preferences（偏好设置）

MacStatus 自有持久化键、迁移规则和重置范围。`AppPreferences` 拥有这些知识，视图和运行 module 使用语义化键，不重复存储字符串。

## Widget catalog（面板目录）

编译期可用面板 module 的唯一目录，拥有身份、名称、图标、设置能力、默认顺序和渲染选择。持久化顺序只保存目录中的稳定身份。

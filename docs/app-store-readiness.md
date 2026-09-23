# Mac App Store 适配状态

当前应用和发布脚本面向站外发行。尚未创建或验证可提交 App Store 的构建。
不能将 Developer ID 公证通过理解为已满足 App Store 审核要求。

## 当前障碍

| 项目 | 当前状态 | 上架前需要完成 |
| --- | --- | --- |
| App Sandbox | Debug / Release 均关闭 | 创建商店构建配置并验证沙盒权限 |
| AppleSMC | 直接连接 AppleSMC user client，读取硬件数据键 | 核实协议及接口是否适用于公开 API 规则；无法支持则替换或移除功能 |
| 其他进程统计 | 使用 top、ps 和 shell 命令 | 在沙盒中验证可用性；必要时重做采集 |
| 特权 Helper | 仅有历史配置文档，没有发行 Target | 不能依靠 root Helper 绕过商店沙盒；商店规则禁止请求提升到 root |
| 应用身份 | 开发默认 Bundle ID 尚待确认 | 注册正式 Bundle ID、设置团队和 App Store 签名 |
| 商店资料 | 未创建 | 截图、隐私政策、支持链接、分类、年龄分级、隐私申报 |
| 验证 | 尚无沙盒实测和 TestFlight 结果 | 真机验证支持的功能，再进行 TestFlight 和审核 |

## 推荐实施方式

先验证采集层在沙盒中能保留哪些功能，再决定是否新增商店 Target / 配置。
若需功能差异，共用 UI 与领域模型，使用明确的编译配置切换采集实现。
商店版本对不可用的监控项应隐藏或准确说明，不应显示虚构读数。

保留现有站外版的工作能力，待商店版有可用采集实现后再加入商店构建流水线。
这样避免产出“能打包但核心功能不能工作”的商店包。

官方依据：[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
第 2.4.5 条（macOS 沙盒、安装、权限和更新）和第 2.5.1 条（公开 API）。

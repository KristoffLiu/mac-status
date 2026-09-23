# MacStatus

macOS 菜单栏电池、功率和系统状态监控工具，使用 SwiftUI / AppKit 构建。

- 菜单栏显示电池状态与适配器功率。
- 面板展示电池健康、功率流向、系统负载与高占用应用。
- 支持调整面板模块、外观和采样频率。

## 支持范围

首版打包目标为 **Apple Silicon（arm64）和 macOS 26.0 或更高版本**。
硬件传感器的可用性随机型变化；功率等数据受底层接口与采样影响。
Intel 和旧版 macOS 尚未纳入发布验证。

应用运行在菜单栏中；打开后请查找电池图标。

## 安装

### GitHub / 下载站

完成首次公开发布后，在仓库 Releases 中下载 `MacStatus-版本-arm64.dmg`，
打开并将 `MacStatus.app` 拖入 `Applications`。
也可下载 ZIP，解压后将应用移入应用程序目录。

正式发行文件经过 Developer ID 签名及 Apple 公证。
文件名含 `-local` 的包是本机测试产物，不具备正式发行签名或公证。
首次公开版本发布之前，请使用下方源码构建流程。

### 从源码构建

安装完整 **Xcode 26.0.1**（已配置的基准版本）和其组件。
后续 Xcode 版本需要另行验证。若系统选择的是 Command Line Tools，
可通过 `DEVELOPER_DIR` 指向完整 Xcode。

下载源码并在仓库根目录执行：

```bash
python3 scripts/release.py build --mode local --version 0.1.0
python3 scripts/release.py verify --artifacts dist/0.1.0-arm64-local
open build/local-DerivedData/Build/Products/Release/MacStatus.app
```

输出：

```text
dist/0.1.0-arm64-local/
  MacStatus-0.1.0-arm64-local.dmg
  MacStatus-0.1.0-arm64-local.zip
  SHA256SUMS.txt
  release.json
```

本机构建使用 ad hoc 签名，无需付费开发者账号。脚本不覆盖已有的版本产物；
重新打包前请将原输出目录移走，或指定新的版本。
也可以打开 `MacStatus/MacStatus.xcodeproj`，选择 MacStatus Scheme，在 Xcode 中运行。

### Homebrew

维护者完成正式 Release 并将生成的 Cask 放入自己的 Tap 后，可执行：

```bash
# 将 OWNER 替换为维护者的 GitHub 账号；Tap 仓库名为 homebrew-tap。
brew tap OWNER/tap
brew install --cask OWNER/tap/mac-status
```

上述命令是配置说明；仓库尚未指定公开发布地址与 Tap。
后续通过 `brew update` 和 `brew upgrade --cask OWNER/tap/mac-status` 更新。

## 开发与发布

```bash
swift test
python3 -m unittest discover -s Tests -p 'test_*.py' -v
```

- [完整发布指南](docs/distribution.md)：证书、公证、GitHub Actions、Homebrew。
- [App Store 适配评估](docs/app-store-readiness.md)：沙盒与数据采集的待办。
- [产品规范](docs/specs/product-spec.md)
- [已知问题](docs/known-issues.md)：尚未确定根因的功率与硬件现象。

应用图标沿用电池与闪电的视觉元素，通过原生矢量绘制生成；修改后执行：

```bash
swift scripts/generate-app-icon.swift
```

## 许可证

本项目采用 [MIT 许可证](LICENSE)，允许修改、商用和再分发，并要求保留版权和许可声明。
安装包内包含同一份许可文本。

## 数据与后台行为

- 实时输入与系统负载优先于电池控制器的缓存；拔线事件立即触发更新。
- 额定适配器瓦数只代表供电能力，不代替实时测量；不可用读数显示 `—`。
- 通过能量差得出的功率标记为估算；三段能耗是 CPU/GPU 启发式分配，不是应用实测瓦数。
- 面板关闭后停止系统详情、应用级采集及流动动画，仅保留菜单栏采样（默认每 10 秒）。睡眠时停止计时。
- 在“通用”中选择登录时启动；系统要求批准时，按界面提示前往登录项设置。

详见 [可靠性与验收记录](docs/reliability.md)。

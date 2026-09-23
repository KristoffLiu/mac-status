# MacStatus 发布指南

## 已实现与发布前待配置

已实现：本机 ad hoc 构建、Release 构建、Developer ID 签名、Hardened Runtime、
Apple 公证和票据附加、DMG / ZIP、SHA256、发布元数据、CI、GitHub Release 草稿、Cask 生成。

正式对外发布还需配置：GitHub 远程仓库、最终 Bundle ID、
Apple Developer Program 证书和公证凭据。项目采用 MIT 许可证，应用包内也包含许可文本。
不要把证书或私钥提交进 Git。
GitHub Release 和 Homebrew 复用相同的站外发行包；Mac App Store 单独评估。

## 1. 发布标识与支持范围

- 首版建议版本：`0.1.0`，Git 标签：`v0.1.0`。
- 脚本将版本和构建号同时写入实际应用，不依赖工程中开发用的版本号。
- 只接受 `MAJOR.MINOR.PATCH` 三段数字；当前未支持 beta 后缀标签。
- 最低系统：macOS 26.0；架构：arm64。
- 正式 Bundle ID 通过 `MACSTATUS_BUNDLE_ID` 设置；确认后也应统一工程中的开发默认值。
- 在正式发布前确定最终 Bundle ID，后续更新保持一致，以保留应用身份和偏好设置。
- 每次发行使用递增构建号；Actions 使用 `GITHUB_RUN_NUMBER`。

## 2. 本机测试包

```bash
python3 scripts/release.py build --mode local --version 0.1.0
```

不需要 Developer ID。脚本强制本机签名，并检查版本、架构、最低系统及签名完整性。
产物目录带 `-local`；不允许由这类包生成正式 Cask。
测试包只用于开发验证；从互联网下载时可能受到 Gatekeeper 拦截。

## 3. 本机正式签名与公证

### 一次性准备

1. 加入 Apple Developer Program。
2. 在 Apple 开发者账户中创建 **Developer ID Application** 证书。
3. 将证书及对应私钥安装到本机钥匙串；`security find-identity -v -p codesigning` 应显示有效身份。
4. 创建用于公证的 Apple 账号专用密码，将公证登录信息存入钥匙串：

```bash
xcrun notarytool store-credentials macstatus-notary
```

按交互提示填写 Apple ID、Team ID、账号专用密码。不要把密码写入文档或 Git。

### 发行

设置下面的非密码配置，替换为真实值：

```bash
export MACSTATUS_SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)'
export MACSTATUS_TEAM_ID='TEAMID'
export MACSTATUS_BUNDLE_ID='com.yourname.MacStatus'
export MACSTATUS_NOTARY_PROFILE='macstatus-notary'

python3 scripts/release.py build --mode release --version 0.1.0 --build-number 1
```

脚本依次：

1. 检查签名身份并构建 arm64 Release，启用 Hardened Runtime 与安全时间戳。
2. 校验应用版本、架构、最低系统和代码签名。
3. 将 app 压缩后提交公证；只接受 `Accepted`，附加票据并验证 Gatekeeper。
4. 从已附加票据的 app 制作 ZIP 和包含 Applications 快捷方式的 DMG。
5. 签名 DMG，再公证并附加其票据，检查 DMG 签名、Gatekeeper 和磁盘映像完整性。
6. 对最终文件计算校验值，写入 `SHA256SUMS.txt` 和 `release.json`。

输出位于 `dist/0.1.0-arm64/`。同版本已有产物时停止，不会覆盖。
使用以下命令挂载 DMG、复制其中的应用并解压 ZIP，验证两份应用的签名、版本、架构、图标和校验值：

```bash
python3 scripts/release.py verify --artifacts dist/0.1.0-arm64
```

该检查不启动应用，不改变 Applications 目录中的安装；正式包还会验证公证票据与 Gatekeeper。
公证失败时输出提交 ID；可用 `xcrun notarytool log 提交ID --keychain-profile macstatus-notary`
查询具体原因。不会自动退回未公证包。

`release.json` 记录版本、构建号、Bundle ID、最低系统、架构、签名模式、Git 提交、工作区状态与源码摘要。
如果构建期间应用源码发生变化，脚本停止打包；等待编辑完成后重新构建。
校验值可检测文件变化，不替代代码签名和 Apple 公证。

## 4. GitHub Actions

### 普通 CI

`.github/workflows/build.yml` 对 main/master 推送、PR 和手动运行执行发布测试，
构建本地测试包并保留 Actions artifact 14 天。此流程不访问 Apple 凭据，也不发布 Release。

使用 `macos-26` runner 和 `/Applications/Xcode_26.0.1.app`。
若 GitHub 将该 Xcode 移出镜像，需要更新两个工作流的 `DEVELOPER_DIR` 并重新验证。

### 配置正式发布环境

在 GitHub 仓库 Settings → Environments 中创建 `release` 环境。

Secrets：

| 名称 | 内容 |
| --- | --- |
| `MACSTATUS_CERTIFICATE_P12_BASE64` | Developer ID Application 证书及私钥导出的加密 `.p12` 文件的 Base64 |
| `MACSTATUS_CERTIFICATE_PASSWORD` | 导出 `.p12` 时设置的密码（非空） |
| `MACSTATUS_SIGNING_IDENTITY` | 完整 `Developer ID Application: … (TEAMID)` 名称 |
| `MACSTATUS_TEAM_ID` | Apple Team ID |
| `MACSTATUS_APPLE_ID` | 公证使用的 Apple ID |
| `MACSTATUS_APP_SPECIFIC_PASSWORD` | Apple 账号专用密码 |

Environment Variables：

| 名称 | 内容 |
| --- | --- |
| `MACSTATUS_BUNDLE_ID` | 确认后的正式 Bundle ID |

可在钥匙串访问中导出证书及私钥为加密 `.p12`。将 Base64 复制到剪贴板：

```bash
base64 -i /安全路径/DeveloperID.p12 | pbcopy
```

把剪贴板内容粘贴到 GitHub Secret。工作流会使用临时钥匙串，并在结束时删除导入材料。

### 触发发行

确认已提交并推送发布代码后：

```bash
git tag -a v0.1.0 -m 'MacStatus 0.1.0'
git push origin v0.1.0
```

工作流会构建、公证、生成 Cask，并创建 **Draft Release**，附带 DMG、ZIP、SHA256、
`release.json`、`mac-status.rb`。检查说明和实际安装体验后，在 GitHub 点击 Publish release。
没有必需的 Secrets / Bundle ID 时流程会失败，不会公开本地测试包。
发行工作流尚需在真实仓库和证书环境中运行验证。

也可手动将本机正式产物上传到同名标签的 GitHub Release。
GitHub 自动生成的 Source code.zip 是源码，不是可安装应用。

## 5. Homebrew Tap

先发布公开可下载的 GitHub Release，然后生成 Cask：

```bash
python3 scripts/release.py cask \
  --artifacts dist/0.1.0-arm64 \
  --repository OWNER/mac-status \
  --output build/Casks/mac-status.rb
```

`OWNER/mac-status` 必须替换成真实仓库。脚本读取最终 DMG 的 SHA256 并验证清单；
Cask 限制 macOS 26 和 arm64，不要求 root，不删除用户偏好设置。

1. 创建公开 GitHub 仓库 `OWNER/homebrew-tap`。
2. 将生成的文件提交到其 `Casks/mac-status.rb`。
3. 验证 `brew tap OWNER/tap` 和 `brew install --cask OWNER/tap/mac-status`。
4. 新版本公开发布后，替换 Cask 中对应版本与校验值（建议重新生成文件）。

也可以直接使用 GitHub Release 中生成的 `mac-status.rb`。
当前流水线不自动向另一个 Tap 仓库推送，不需要额外的跨仓库写权限。

## 6. 安装与更新验收

- 从浏览器下载正式 DMG，在另一台受支持的 Mac 上正常打开。
- 拖入 Applications 后运行，确认菜单栏出现图标、面板可以打开和退出。
- 检查电池、充电状态、功率及系统数据；传感器数据需真机验证。
- 验证离线启动（已附加公证票据）、重新登录以及从上一版本替换安装。
- Homebrew 用户通过更新 Tap 后运行 `brew upgrade --cask OWNER/tap/mac-status` 更新。
- 手动下载用户目前通过重新下载并替换应用更新；尚未集成应用内自动更新。
- 删除 Applications 中的应用即可卸载；当前没有安装特权 Helper 或后台守护程序。

## 官方参考

- [Apple 站外公证](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple 自定义公证流程](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [GitHub macOS 26 runner 镜像](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
- [Homebrew Cask](https://docs.brew.sh/Cask-Cookbook)
- [Homebrew Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)

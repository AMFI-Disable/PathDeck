# PathDeck

[English](readme.md) · [更新日志](changelog.md) · [安全策略](security.md) · [MIT 许可证](license)

[![发布版本 v1.0.1](https://img.shields.io/badge/Release-v1.0.1-blue?style=flat-square)](https://github.com/AMFI-Disable/PathDeck/releases)

## 功能与使用

PathDeck 是用于 macOS 的原生 SwiftUI shell 配置编辑器，可读取 `~/.zshrc` 和 `~/.bash_profile`。v1.0.1 是最近一次独立发布；有关后续整合计划，请参阅[更新日志](changelog.md)。

- **PATH 路径顺序**：拖动条目可调整命令查找顺序。状态标记可区分已存在和失效的目录。
- **命令别名**：创建命令快捷方式，也可将别名注释掉，保留原定义以便重新启用。
- **环境变量**：敏感值默认遮盖，显示前需要进行本机身份验证。提交问题时请隐去变量值。
- **备份与恢复**：写入前会为对应的 shell 配置创建带时间戳的本地备份。可在备份界面选择快照进行恢复。

配置解析和备份都在本机运行。编辑后在新 shell 会话中检查命令解析结果。

## 安装

从 [v1.0.1 发布页](https://github.com/AMFI-Disable/PathDeck/releases/tag/v1.0.1) 下载 `PathDeck.dmg`，在下载目录运行 `shasum -a 256 PathDeck.dmg` 并与发布页所列 SHA-256 摘要核对。打开磁盘映像，将 PathDeck 拖入“应用程序”。该开源构建未经 Apple 公证；若 Gatekeeper 提示，完成验证后可在“系统设置 → 隐私与安全性”中选择“仍要打开”。

## 构建与测试

在 macOS 14 或更新版本上使用 Swift 5.10 或更高版本：

```bash
git clone https://github.com/AMFI-Disable/PathDeck.git
cd PathDeck
swift test
./scripts/build.sh
```

脚本在仓库根目录生成 `PathDeck.app` 和 `PathDeck.dmg`。测试覆盖解析与备份恢复。提交功能或缺陷修复前，请阅读[贡献指南](contributing.zh-cn.md)。

<div align="center">
  <img src="Resources/AppIcon-Source.png" width="180" alt="LEO-MACOS快捷键助手图标">
  <h1>LEO-MACOS快捷键助手</h1>
  <p><strong>按住一个键，看见当前应用的全部快捷键。松开，即刻消失。</strong></p>
  <p>
    <a href="README.md">简体中文</a> ·
    <a href="README_EN.md">English</a>
  </p>
  <p>
    <a href="https://github.com/leoyoyofiona/LEO-MACOS-Shortcut-Assistant/releases/latest"><img src="https://img.shields.io/badge/下载-最新版本-2ea44f?style=for-the-badge&logo=apple" alt="下载最新版"></a>
    <img src="https://img.shields.io/badge/macOS-15%2B-111111?style=for-the-badge&logo=apple" alt="macOS 15+">
    <img src="https://img.shields.io/badge/芯片-Apple%20Silicon-blue?style=for-the-badge" alt="Apple Silicon">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="MIT License"></a>
  </p>
</div>

![功能演示](docs/images/demo.gif)

LEO-MACOS快捷键助手是一款原生 macOS 工具。它会识别当前正在使用的应用，并读取该应用菜单中公开的快捷键。按住自定义触发键时，快捷键以半透明水玻璃面板呈现；松开后面板立即隐藏。

## 亮点

- **跟随当前应用**：Finder、Safari、ChatGPT、办公软件和多数原生 macOS 应用均可实时读取。
- **按住显示，松开隐藏**：不打断工作流，也不会长期占据屏幕。
- **自定义触发键**：支持左/右 Control、Option、Command 和 Fn。
- **中英双语**：界面和常见菜单命令支持中文与 English；未收录命令使用 Apple 本机翻译并缓存。
- **自适应水玻璃面板**：自动适配浅色/深色环境、屏幕尺寸和快捷键数量。
- **完整浏览**：支持鼠标滚轮及触控板纵向、横向滚动，不截断长菜单。
- **本地优先**：快捷键读取、设置和翻译缓存均保留在本机，不上传应用菜单内容。详见[隐私说明](PRIVACY.md)。

## 安装

### 直接下载

1. 前往 [Releases](https://github.com/leoyoyofiona/LEO-MACOS-Shortcut-Assistant/releases/latest)。
2. 下载 `.dmg`（推荐）或 `.zip`。
3. 将 `LEO-MACOS快捷键助手.app` 拖入“应用程序”。
4. 首次启动后，按引导开启“辅助功能”和“输入监控”。

> [!IMPORTANT]
> 当前是社区预览版，尚未完成 Apple Developer ID 公证。如果 macOS 阻止首次打开，请在 Finder 中右键应用，选择“打开”，然后再次确认“打开”。不要关闭 Gatekeeper。

### 从源码构建

需要 macOS 15+ 和 Swift 6：

```zsh
git clone https://github.com/leoyoyofiona/LEO-MACOS-Shortcut-Assistant.git
cd LEO-MACOS-Shortcut-Assistant
chmod +x build-app.sh
./build-app.sh
open "dist/LEO-MACOS快捷键助手.app"
```

## 使用方法

1. 启动应用，在设置中选择显示语言、触发键和面板位置。
2. 切换到希望查看快捷键的应用。
3. 按住触发键显示面板。
4. 使用鼠标滚轮或触控板浏览较长内容。
5. 松开触发键隐藏面板。

## 功能截图

### 中文设置

![中文设置](docs/images/settings-zh.png)

### English settings

![English settings](docs/images/settings-en.png)

### 快捷键水玻璃面板

![快捷键面板](docs/images/panel-en.png)

## 权限用途

| 权限 | 用途 |
| --- | --- |
| 辅助功能 | 识别当前应用并读取其菜单快捷键 |
| 输入监控 | 识别触发键的按下与松开 |

应用不会记录普通键盘输入，也不会拦截或修改按键事件。部分跨平台应用不会向 macOS 辅助功能接口公开全部命令，此时显示内容可能少于应用官方文档。

## 路线图

- [ ] Developer ID 签名与 Apple 公证
- [ ] 登录时自动启动
- [ ] 应用专属官方快捷键资料库
- [ ] 用户自定义快捷键补充与收藏
- [ ] Homebrew Cask
- [ ] 更多语言

## 参与贡献

欢迎提交 Issue、功能建议和 Pull Request。开始前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

## 致谢

项目展示结构参考了优秀的开源 macOS 工具项目，例如 [Ice](https://github.com/jordanbaird/Ice)、[Rectangle](https://github.com/rxhanson/Rectangle)、[AltTab](https://github.com/lwouis/alt-tab-macos) 和 [Loop](https://github.com/MrKai77/Loop)。本项目未复制其代码或视觉资产。

## 许可证

[MIT License](LICENSE)

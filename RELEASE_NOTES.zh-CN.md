# PulseDock 0.1.0 初版发布说明

PulseDock 是一个本地优先的 macOS 菜单栏性能诊断工具。它的重点不是堆满所有传感器数据，而是帮助用户快速判断当前 Mac 为什么变卡。

## 安装方式

1. 下载 `PulseDock-0.1.0.dmg`。
2. 打开 DMG。
3. 将 `PulseDock.app` 拖到 `Applications`。
4. 从 `Applications` 启动 PulseDock。

首次启动时，如果 macOS 提示来自未识别开发者，请在“系统设置 > 隐私与安全性”中手动允许打开。当前初版尚未接入签名和公证。

## 主要功能

- 菜单栏常驻，支持紧凑弹窗查看当前状态。
- 桌面端仪表盘，包含主页、进程、指标、设置和关于页面。
- 健康分数和一句话诊断，优先解释当前性能压力来源。
- CPU、Load Average、内存、压缩内存、Swap、磁盘、网络、电池和热压力指标。
- Top 进程列表和桌面端进程详情。
- 识别 IDEA、Java、Gradle、Maven、Xcode、Swift、Simulator、Docker、Node、Chrome、Codex 等常见开发进程。
- 本地趋势历史，支持历史记录开关、保留时间和清除历史。
- 本地隐私说明：无账号、无遥测、无云同步、无上传。
- 中英文界面切换。
- 菜单栏右键支持打开主界面和退出 App。

## 当前限制

- 暂未接入开机启动。
- 暂未签名和公证。
- 当前 DMG 按本机环境构建，尚未提供 Universal App 发布包。
- CPU/GPU 温度、GPU 使用率、显存和风扇转速目前会在界面中标记为不可用。
- 进程级磁盘 I/O、进程级网络 I/O 和 per-process 压缩内存暂未实现。
- 主题选择已有设置入口，强制应用浅色/深色外观仍需后续完善。

## 系统要求

- macOS 13 Ventura 或更新版本。
- 当前发布包主要面向 Apple Silicon Mac 构建。

## 隐私

PulseDock 只在本机采集性能诊断所需信息。历史趋势保存在本机 `UserDefaults` 中，关闭历史记录或清除历史后会停止写入并移除本地样本。

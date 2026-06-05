<h1 align="center">PulseDock</h1>

<p align="center">
  <strong>Local-first macOS menu bar performance monitor</strong>
</p>

<p align="center">
  Understand CPU, memory, disk, network, processes, battery, thermal state, and system pressure from one quiet dashboard.
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-13%2B-111111?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6.2-F05138?style=for-the-badge&logo=swift&logoColor=white">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-Desktop%20%2B%20Menu%20Bar-0A84FF?style=for-the-badge">
  <img alt="Privacy" src="https://img.shields.io/badge/Privacy-No%20Telemetry-34C759?style=for-the-badge">
</p>

<p align="center">
  <a href="#中文">中文</a> | <a href="#english">English</a>
</p>

---

## 中文

PulseDock 是一个本地优先的 macOS 菜单栏性能监控工具，用于轻量级性能诊断。它的目标不是做完整的系统清理套件，而是帮助你快速理解 Mac 为什么可能变慢。

PulseDock 默认只在本机运行：不需要账号、不包含遥测、不做云同步，也不会上传性能历史数据。

### 系统要求

- macOS 13 Ventura 或更新版本
- 支持 Swift 6.2 工具链的 Xcode

### 运行

```sh
./scripts/build-app.sh
open .build/PulseDock.app
```

应用会以菜单栏工具的形式运行，不显示 Dock 图标。启动后会打开桌面仪表盘，并保留菜单栏状态项。

- 左键点击菜单栏图标：打开紧凑诊断面板
- 右键点击菜单栏图标：前往桌面端主页或退出 App
- `Cmd + ,`、面板中的齿轮按钮、桌面端侧边栏都可以进入设置页

不要使用 `swift run PulseDock` 做交互测试。SwiftPM 可执行文件不是 macOS `.app` 包，缺少主 bundle 标识时，AppKit 创建菜单栏状态项可能会崩溃。

### 构建

```sh
swift build
```

构建可运行的本地 `.app` 包：

```sh
./scripts/build-app.sh
```

### 当前功能范围

已包含：

- 菜单栏状态显示
- 紧凑弹窗：健康摘要、关键指标、顶部进程和诊断信息
- CPU、负载、内存、磁盘、网络、电池、热状态和进程采样
- 指标页按 CPU、GPU、主机内存、磁盘、网络、流量、风扇、电池分组展示
- 系统无法稳定读取的硬件传感器会显示为不可用，不伪造数值
- CPU、内存、网络和磁盘活动的短期趋势
- 桌面端进程搜索、排序、选择和详情建议
- 桌面端侧边栏：主页、进程、指标、设置、关于
- 使用 `UserDefaults` 保存用户设置
- 本地隐私说明
- 本地历史记录开关、保留时间设置和清除历史操作

暂不包含：

- 风扇控制或系统清理
- 自动结束进程
- 账号、云同步、遥测或远程配置
- App Store 购买或订阅
- 复杂告警规则编辑
- 开机启动底层实现

### 隐私

PulseDock 只在本机采集性能诊断所需数据。当前版本没有账号系统、没有遥测、没有远程同步，也没有上传诊断历史的路径。

如果启用历史记录，历史数据也应保留在本机。关闭历史记录或清除历史数据后，数据层应停止写入并移除本地历史。

## English

PulseDock is a local-first macOS menu bar app for lightweight performance diagnosis. Its goal is not to become a full system cleanup suite, but to help you quickly understand why your Mac may feel slow.

PulseDock runs locally by default: no account, no telemetry, no cloud sync, and no upload of performance history.

### Requirements

- macOS 13 Ventura or newer
- Xcode with Swift 6.2 toolchain support

### Run

```sh
./scripts/build-app.sh
open .build/PulseDock.app
```

The app runs as a menu bar utility without a Dock icon. It opens the desktop dashboard on launch and keeps a menu bar status item.

- Left-click the menu bar icon: open the compact diagnostic popover
- Right-click the menu bar icon: open the desktop overview or quit the app
- Use `Cmd + ,`, the gear button in the popover, or the desktop sidebar to open Settings

Do not use `swift run PulseDock` for interactive testing. The SwiftPM executable is not a macOS `.app` bundle and can crash when AppKit creates the menu bar status item without a bundle identifier.

### Build

```sh
swift build
```

For a runnable local `.app` bundle:

```sh
./scripts/build-app.sh
```

### Current Scope

Included:

- Menu bar status display
- Compact popover with health summary, key metrics, top processes, and diagnosis
- CPU, load average, memory, disk, network, battery, thermal, and process sampling
- Grouped metrics for CPU, GPU, host memory, disk, network, traffic, fan, and battery
- Hardware sensors that cannot be read reliably are shown as unavailable instead of fabricated values
- Short-term trends for CPU, memory, network, and disk activity
- Desktop process search, sorting, selection, and detail guidance
- Desktop sidebar sections for overview, processes, metrics, settings, and about
- User settings persisted with `UserDefaults`
- Local privacy notice
- Local history controls, retention settings, and clear-history action

Not included yet:

- Fan control or system cleanup
- Automatically killing processes
- Account, cloud sync, telemetry, or remote configuration
- App Store purchases or subscriptions
- Complex alert rule editing
- Startup item implementation

### Privacy

PulseDock is designed to collect performance data locally on the Mac. The current version has no account system, no telemetry, no remote sync, and no upload path for diagnostic history.

If history is enabled, history data should remain local. If history is disabled or cleared, the data layer should stop writing local history and remove stored history.

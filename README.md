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
  English | <a href="README.zh-CN.md">中文</a>
</p>

---

PulseDock is a local-first macOS menu bar app for lightweight performance diagnosis. Its goal is not to become a full system cleanup suite, but to help you quickly understand why your Mac may feel slow.

PulseDock runs locally by default: no account, no telemetry, no cloud sync, and no upload of performance history.

## Requirements

- macOS 13 Ventura or newer
- Xcode with Swift 6.2 toolchain support

## Run

```sh
./scripts/build-app.sh
open .build/PulseDock.app
```

The app runs as a menu bar utility without a Dock icon. It opens the desktop dashboard on launch and keeps a menu bar status item.

- Left-click the menu bar icon: open the compact diagnostic popover
- Right-click the menu bar icon: open the desktop overview or quit the app
- Use `Cmd + ,`, the gear button in the popover, or the desktop sidebar to open Settings

Do not use `swift run PulseDock` for interactive testing. The SwiftPM executable is not a macOS `.app` bundle and can crash when AppKit creates the menu bar status item without a bundle identifier.

## Build

```sh
swift build
```

For a runnable local `.app` bundle:

```sh
./scripts/build-app.sh
```

## Current Scope

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

## Privacy

PulseDock is designed to collect performance data locally on the Mac. The current version has no account system, no telemetry, no remote sync, and no upload path for diagnostic history.

If history is enabled, history data should remain local. If history is disabled or cleared, the data layer should stop writing local history and remove stored history.

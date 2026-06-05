# PulseDock

PulseDock is a SwiftPM macOS menu bar app for lightweight performance diagnosis. Its first goal is to explain why a Mac feels slow, not to become a full system maintenance suite.

The MVP is local-first: no account system, no telemetry, no cloud sync, and no upload of performance history.

## Requirements

- macOS 13 Ventura or newer
- Xcode with Swift 6.2 toolchain support

## Run

```sh
./scripts/build-app.sh
open .build/PulseDock.app
```

The app runs as a menu bar utility without a Dock icon. It opens the desktop dashboard on launch and keeps a menu bar status item. Left-click the menu bar item to open the compact diagnostic popover. Right-click it to open the desktop overview or quit the app. Use `Cmd + ,`, the gear button in the panel, or the desktop sidebar to open the Settings page inside the desktop dashboard.

Do not use `swift run PulseDock` for interactive testing. The SwiftPM executable is not a macOS `.app` bundle and can crash when AppKit creates the status item without a bundle identifier.

## Build

```sh
swift build
```

For a runnable local app bundle:

```sh
./scripts/build-app.sh
```

## MVP Scope

Included in the initial scope:

- Menu bar status display
- Popover dashboard for health summary, key metrics, top processes, and diagnosis
- CPU, load average, memory, disk, network, battery, thermal, and process-oriented sampling hooks
- Grouped metrics for CPU, GPU, host memory, disk, network, traffic, fan, and battery; unavailable hardware sensors are shown as unavailable instead of fabricated values
- Short-term local trends for CPU, memory, network, and disk activity
- Desktop process search, sorting, selection, and detail guidance
- Desktop sidebar sections for overview, processes, metrics, settings, and about
- User settings persisted with `UserDefaults`
- Local privacy notice
- Local history controls, retention settings, and clear-history action

Not included in the MVP:

- Fan control or system cleanup
- Killing processes automatically
- Account, cloud sync, telemetry, or remote configuration
- App Store purchases or subscriptions
- Complex alert rule editing
- Startup item implementation

## Privacy

PulseDock is designed to collect performance data locally on the Mac. The MVP has no account system, no telemetry, no remote sync, and no upload path for diagnostic history.

If history is enabled, history data should remain local. If history is disabled or cleared, the data layer should stop writing local history and remove stored history.

# PulseDock Agent Notes

## Project

PulseDock is a SwiftPM macOS SwiftUI menu bar app for local performance monitoring and diagnosis.

Primary product direction:

- Explain current performance bottlenecks before showing raw metrics.
- Keep the app lightweight and low-noise.
- Preserve local-first privacy: no account, no telemetry, no cloud sync, no upload.

## Tech Stack

- Swift Package Manager
- SwiftUI for app and settings UI
- AppKit bridge for menu bar status item and popover
- `UserDefaults` for lightweight settings
- Minimum platform: macOS 13

## Directory Map

- `Package.swift`: SwiftPM manifest. Do not edit unless dependency, target, resource, or platform configuration changes are explicitly requested.
- `Sources/PulseDockApp/AppDelegate.swift`: AppKit menu bar integration and popover wiring.
- `Sources/PulseDockApp/AppModel.swift`: Shared app state, sampling timer, settings updates.
- `Sources/PulseDockApp/Core/`: Sampling, snapshots, and diagnosis logic.
- `Sources/PulseDockApp/UI/`: Dashboard and menu popover UI.
- `Sources/PulseDockApp/Settings/`: Settings model, settings UI, and privacy entry.
- `README.md`: Human-facing project entry point.

## Collaboration Notes

- Keep feature work split by layer when possible: Core sampling/diagnosis, Dashboard UI, Settings, and documentation.
- Avoid broad refactors while MVP behavior is still forming.
- When multiple agents or contributors are active, keep write scopes explicit and do not revert unrelated changes.

## Settings Conventions

- Persist lightweight app settings with `UserDefaults`.
- Default refresh interval is 2 seconds.
- Supported refresh intervals are 1, 2, and 5 seconds.
- Keep startup-at-login UI honest: do not claim it works until the underlying macOS login item implementation is added.
- History controls must support enabled/disabled state, retention choice, and a clear-history action.
- Privacy copy must explicitly state local collection, no account, no telemetry, and no upload.

## Verification

Use project-provided or SwiftPM commands first:

```sh
swift build
./scripts/build-app.sh
open .build/PulseDock.app
```

Before reporting completion for code changes, run the smallest relevant check. For settings or model changes, `swift build` is the minimum verification.

For visible UI changes, inspect the app bundle launched from `.build/PulseDock.app` when practical. Avoid `swift run PulseDock` for interactive testing because the bare executable lacks a main bundle identifier and can crash while creating the menu bar status item.

## Git Safety

- Do not revert unrelated changes.
- Expect multiple agents or users to edit this repository at the same time.
- Check the diff before committing.
- Do not force-push, rewrite history, or reset without explicit approval.

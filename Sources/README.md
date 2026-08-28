# Modular build layout

Internal modules (`Logging`, `Http`, `Concurrency`, `BackoffCounter`,
`PeriodicRecorderWorker`, `Tracker`, `Streaming`) live here; the rest in `Split/`.

Three channels, two packaging shapes:

| Channel | Shape |
|---|---|
| **SPM** | modular — separate modules (`import Http`, …) |
| **Xcode module targets** | modular |
| **CocoaPods / Carthage / xcframework** | flattened — one `Split` module/framework |

## The switch

Anything that only works when a module compiles on its own (cross-module `import`s,
the `typealias` bridges in `Split/ModuleConnectors/`, and helpers duplicated with
`Split/`) is guarded:

```swift
#if SWIFT_PACKAGE || SPLIT_MODULAR
import Logging
#endif
```

- `SWIFT_PACKAGE`: auto under SPM.
- `SPLIT_MODULAR`: set only on the 7 module targets in `Split.xcodeproj`
  (`SWIFT_ACTIVE_COMPILATION_CONDITIONS`).
- Neither defined (CocoaPods, Carthage's `Split` target) → everything
  resolves inside the flattened `Split`.

The `Split`/`SplitWatchOS` Xcode targets compile the module sources into themselves and
don't link the module frameworks, so Carthage ships one framework. CocoaPods flattens
via `s.source_files` globbing `Sources/**`.

## How to add a new module

1. `Sources/<Module>/` with the `.swift` files; tests under `Sources/<Module>/Tests/`.
2. Guard cross-module `import`s and Split-duplicated helpers with `#if SWIFT_PACKAGE || SPLIT_MODULAR`.
3. **Package.swift**: add `.target` + `.testTarget` (list the module in the test deps).
4. **Split.xcodeproj**: new framework target with `SPLIT_MODULAR` in its
   `SWIFT_ACTIVE_COMPILATION_CONDITIONS` (keep `$(inherited)`); add its sources to the
   `Split` **and** `SplitWatchOS` targets.
5. Bridged names → `typealias`es under `Split/ModuleConnectors/`, guarded the same way.

## Verify

```sh
swift test                                                              # SPM
pod lib lint Split.podspec --allow-warnings                             # CocoaPods
xcodebuild build -scheme Split -destination generic/platform=iOS \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES                                  # Carthage
```
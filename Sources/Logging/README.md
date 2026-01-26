# Logging

## What this module provides

- `Logger`: shared logger with convenience methods `Logger.v/d/i/w/e`
- `LogLevel`: logging level enum
- `LogPrinter`: output interface (default prints to stdout)
- `TimeChecker`: helper to measure and log time intervals
- `DateProvider`: host-provided timestamp + label formatting (keeps this module independent from your app’s time utilities)

## Usage

### 1) Configure required dependencies

This module intentionally does **not** implement “real time” by default. You must provide a `DateProvider` from the host app/module (e.g. using `Foundation.Date`, your own time utils, etc).

Example:

```swift
import Logging
import Foundation

struct AppDateProvider: DateProvider {
  func nowMillis() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
  func nowLabel() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH:mm:ss.SSS"
    return formatter.string(from: Date())
  }
}

Logger.shared.dateProvider = AppDateProvider()
Logger.shared.level = .info
```

### 2) Log

```swift
import Logging

Logger.i("SDK initialized")
Logger.w("Something looks off", ["context": "value"])
Logger.e("Something failed")
```

### Optional: customize output

```swift
import Logging

final class MyPrinter: LogPrinter {
  func stdout(_ items: Any...) {
    // route to OSLog, a file, your analytics, etc.
  }
}

Logger.shared.printer = MyPrinter()
```

### Optional: TimeChecker

`TimeChecker` uses `Logger.shared.dateProvider` by default.

```swift
import Logging

TimeChecker.start()
// ... do work ...
TimeChecker.logInterval("Finished work")
```

## Notes

- If the consumer has its own log levels, do the mapping in the consumer module (e.g. map `YourLogLevel` → `LogLevel`).

## Running tests

### Swift Package Manager

From the repository root:

```bash
swift test --filter LoggingTests
```

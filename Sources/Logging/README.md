# Logging

## What this module provides

- `Logger`: shared logger with convenience methods `Logger.v/d/i/w/e`
- `LogLevel`: logging level enum
- `LogPrinter`: output interface (default prints to stdout)
- `TimeChecker`: helper to measure and log time intervals
- `DateProvider`: timestamp + label formatting (ships with a `DefaultDateProvider` backed by `Foundation.Date`)

## Usage

### 1) Configure (optional)

The module ships with a `DefaultDateProvider` that uses `Foundation.Date`, so it works out of the box. You can still supply a custom `DateProvider` if you need different formatting or a custom clock:

```swift
import Logging

// Optional: override the default provider
Logger.shared.dateProvider = MyCustomDateProvider()
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

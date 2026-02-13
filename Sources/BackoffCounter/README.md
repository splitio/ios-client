# BackoffCounter

A thread-safe exponential backoff implementation for retry logic.

## Overview

This module provides two main components:

- **BackoffCounter**: Calculates exponential backoff times for retry operations
- **BackoffCounterTimer**: Schedules operations with automatic backoff delays

## Usage

### Basic BackoffCounter

```swift
// Create a counter with base 1 (delays: 1s, 2s, 4s, 8s, 16s... up to 30 min)
let counter = DefaultBackoffCounter(backoffBase: 1)

// Get next retry time (exponentially increasing)
let delay1 = counter.getNextRetryTime() // 1.0
let delay2 = counter.getNextRetryTime() // 2.0
let delay3 = counter.getNextRetryTime() // 4.0

// Reset after successful operation
counter.resetCounter()
```

### Custom Configuration

```swift
// Higher base = faster growth (delays: 1s, 4s, 16s, 64s...)
let aggressiveCounter = DefaultBackoffCounter(backoffBase: 2)

// Custom max time limit (default is 1800 seconds / 30 minutes)
let limitedCounter = DefaultBackoffCounter(backoffBase: 1, maxTimeLimit: 60)
```

### BackoffCounterTimer

```swift
let counter = DefaultBackoffCounter(backoffBase: 1)
let timer = DefaultBackoffCounterTimer(backoffCounter: counter)

// Schedule a retry operation
timer.schedule {
    // This will be called after the backoff delay
    performRetryOperation()
}

// Cancel pending retry and reset counter
timer.cancel()
```

## Backoff Formula

The retry time is calculated as:

```
retryTime = (backoffBase * 2) ^ attemptCount
```

Where `attemptCount` starts at 0 and increments with each call to `getNextRetryTime()`.

### Example Sequences

| Base | Attempt 0 | Attempt 1 | Attempt 2 | Attempt 3 | Max (default) |
|------|-----------|-----------|-----------|-----------|---------------|
| 1    | 1s        | 2s        | 4s        | 8s        | 1800s         |
| 2    | 1s        | 4s        | 16s       | 64s       | 1800s         |
| 3    | 1s        | 6s        | 36s       | 216s      | 1800s         |

## Thread Safety

Both `DefaultBackoffCounter` and `DefaultBackoffCounterTimer` are thread-safe and conform to `Sendable`.

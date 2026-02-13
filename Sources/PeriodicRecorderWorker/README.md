# PeriodicRecorderWorker

A module that provides periodic execution of flush operations for recorder workers.

## Overview

This module contains:
- `PeriodicRecorderWorker` - Protocol and implementation for workers that periodically flush data
- `PeriodicTimer` - Protocol and implementation for periodic timers using GCD
- `RecorderWorker` - Protocol for flushable workers

## Usage

```swift
import PeriodicRecorderWorker

// Create a recorder worker that implements the RecorderWorker protocol
class MyRecorderWorker: RecorderWorker {
    func flush() {
        // Your flush implementation
    }
}

// Create a periodic timer
let timer = DefaultPeriodicTimer(interval: 30) // 30 seconds interval

// Create the periodic recorder worker
let worker = DefaultPeriodicRecorderWorker(
    timer: timer,
    recorderWorker: MyRecorderWorker()
)

// Start periodic flushing
worker.start()

// Pause/Resume as needed
worker.pause()
worker.resume()

// Stop and cleanup
worker.stop()
worker.destroy()
```

## Components

### PeriodicRecorderWorker

Protocol defining the lifecycle methods for periodic workers:
- `start()` - Start periodic execution
- `pause()` - Pause execution temporarily  
- `resume()` - Resume after pause
- `stop()` - Stop the timer
- `destroy()` - Cleanup resources

### PeriodicTimer

Protocol for timers with methods:
- `trigger()` - Start the timer
- `stop()` - Stop the timer
- `destroy()` - Cancel and cleanup
- `handler(_:)` - Set the callback

### RecorderWorker

Protocol for workers that can be flushed:
- `flush()` - Execute the flush operation

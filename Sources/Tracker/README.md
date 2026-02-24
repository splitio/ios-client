# Tracker

A module that provides event tracking functionality with validation and logging.

## Overview

This module contains:
- `Tracker` - Protocol and implementation for tracking events
- `TrackerEvent` - Event data model
- `TrackerEventValidator` - Protocol for event validation
- `TrackerPropertyValidator` - Protocol for property validation
- `TrackerLogger` - Protocol for logging

## Usage

```swift
import Tracker

// Create validator implementations
class MyEventValidator: TrackerEventValidator {
    func validate(key: String?, trafficTypeName: String?, eventTypeId: String?,
                  value: Double?, properties: [String: Any]?,
                  isSdkReady: Bool) -> TrackerValidationError? {
        // Your validation logic
        return nil
    }
}

class MyPropertyValidator: TrackerPropertyValidator {
    func validate(properties: [String: Any]?,
                  initialSizeInBytes: Int,
                  validationTag: String) -> TrackerPropertyResult {
        return TrackerPropertyResult.valid(properties: properties, sizeInBytes: 0)
    }
}

class MyLogger: TrackerLogger {
    func log(errorInfo: TrackerValidationError, tag: String) { }
    func e(message: String, tag: String) { }
    func v(_ message: String) { }
}

// Create the tracker with closures for event push and telemetry
let tracker = DefaultTracker(
    defaultTrafficType: "user",
    initialEventSizeInBytes: 1024,
    eventValidator: MyEventValidator(),
    propertyValidator: MyPropertyValidator(),
    logger: MyLogger(),
    onEventPush: { event in
        // Handle the event (e.g., send to server)
        print("Event pushed: \(event.eventType)")
    },
    onTrackLatency: { latency in
        // Record telemetry
        print("Track latency: \(latency)ms")
    }
)

// Track an event
let success = tracker.track(
    eventType: "purchase",
    trafficType: nil, // Uses defaultTrafficType
    value: 99.99,
    properties: ["item": "widget"],
    matchingKey: "user123",
    isSdkReady: true
)
```

## Components

### Tracker

Protocol defining the tracking interface:
- `isTrackingEnabled` - Enable/disable tracking
- `track(...)` - Track an event

### TrackerEvent

Data model for events:
- `trafficType` - Traffic type name
- `eventType` - Event type identifier
- `key` - Matching key
- `value` - Optional numeric value
- `timestamp` - Event timestamp
- `properties` - Optional properties dictionary
- `sizeInBytes` - Size of the event

### TrackerEventValidator

Protocol for validating events before tracking.

### TrackerPropertyValidator

Protocol for validating event properties.

### TrackerLogger

Protocol for logging validation errors and messages.

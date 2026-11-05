//  TrackerTests
//  Copyright © 2022 Split. All rights reserved.

import XCTest
@testable import Tracker

class TrackerTest: XCTestCase {

    var tracker: Tracker!
    var eventValidator: TrackerEventValidatorStub!
    var propertyValidator: TrackerPropertyValidatorStub!
    var logger: TrackerLoggerStub!
    var pushedEvents: [TrackerEvent] = []
    var recordedLatencies: [Int64] = []

    override func setUp() {
        eventValidator = TrackerEventValidatorStub()
        propertyValidator = TrackerPropertyValidatorStub()
        logger = TrackerLoggerStub()
        pushedEvents = []
        recordedLatencies = []

        tracker = DefaultTracker(
            defaultTrafficType: "user",
            initialEventSizeInBytes: 1024,
            eventValidator: eventValidator,
            propertyValidator: propertyValidator,
            logger: logger,
            onEventPush: { [weak self] event in
                self?.pushedEvents.append(event)
            },
            onTrackLatency: { [weak self] latency in
                self?.recordedLatencies.append(latency)
            }
        )
    }

    func testTrackEnabled() {
        tracker.isTrackingEnabled = true
        propertyValidator.result = TrackerPropertyResult.valid(properties: nil, sizeInBytes: 100)

        let result = tracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertEqual(pushedEvents.count, 1)
        XCTAssertEqual(recordedLatencies.count, 1)
    }

    func testTrackDisabled() {
        tracker.isTrackingEnabled = false

        let result = tracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertFalse(result)
        XCTAssertEqual(pushedEvents.count, 0)
        XCTAssertEqual(recordedLatencies.count, 0)
    }

    func testTrackWithValidationError() {
        tracker.isTrackingEnabled = true
        eventValidator.validationError = TrackerValidationError(isError: true, message: "Invalid key")

        let result = tracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertFalse(result)
        XCTAssertEqual(pushedEvents.count, 0)
    }

    func testTrackWithPropertyValidationError() {
        tracker.isTrackingEnabled = true
        propertyValidator.result = TrackerPropertyResult.invalid(message: "Properties too large", sizeInBytes: 50000)

        let result = tracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: nil,
            properties: ["key": "value"],
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertFalse(result)
        XCTAssertEqual(pushedEvents.count, 0)
    }

    func testTrackUsesDefaultTrafficType() {
        tracker.isTrackingEnabled = true
        propertyValidator.result = TrackerPropertyResult.valid(properties: nil, sizeInBytes: 100)

        let result = tracker.track(
            eventType: "test_event",
            trafficType: nil,
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertEqual(pushedEvents.count, 1)
        XCTAssertEqual(pushedEvents.first?.trafficType, "user")
    }

    func testTrackWithValue() {
        tracker.isTrackingEnabled = true
        propertyValidator.result = TrackerPropertyResult.valid(properties: nil, sizeInBytes: 100)

        let result = tracker.track(
            eventType: "purchase",
            trafficType: "user",
            value: 99.99,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertEqual(pushedEvents.first?.value, 99.99)
    }
}

// MARK: - Test Stubs

final class TrackerEventValidatorStub: TrackerEventValidator, @unchecked Sendable {
    var validationError: TrackerValidationError?

    func validate(key: String?, trafficTypeName: String?, eventTypeId: String?, value: Double?, properties: [String: Any]?, isSdkReady: Bool) -> TrackerValidationError? {
        validationError
    }
}

final class TrackerPropertyValidatorStub: TrackerPropertyValidator, @unchecked Sendable {
    var result = TrackerPropertyResult.valid(properties: nil, sizeInBytes: 0)

    func validate(properties: [String: Any]?, initialSizeInBytes: Int, validationTag: String) -> TrackerPropertyResult {
        result
    }
}

final class TrackerLoggerStub: TrackerLogger, @unchecked Sendable {
    var loggedErrors: [TrackerValidationError] = []
    var errorMessages: [String] = []
    var verboseMessages: [String] = []

    func log(errorInfo: TrackerValidationError, tag: String) {
        loggedErrors.append(errorInfo)
    }

    func e(message: String, tag: String) {
        errorMessages.append(message)
    }

    func v(_ message: String) {
        verboseMessages.append(message)
    }
}

//
//  TrackerValidatorArgumentsTest.swift
//  SplitTests
//
//  Regression coverage for issue-61: DefaultTracker must pass the event type
//  as eventTypeId and the resolved traffic type as trafficTypeName to the validator.
//

import Foundation

import XCTest
@testable import Split

class TrackerValidatorArgumentsTest: XCTestCase {

    private var validator: ArgumentRecordingEventValidator!
    private var propertyValidator: PropertyValidatorStub!

    override func setUp() {
        super.setUp()
        validator = ArgumentRecordingEventValidator()
        propertyValidator = PropertyValidatorStub()
        propertyValidator.validateResult = PropertyValidationResult.valid(
            properties: nil,
            sizeInBytes: 0
        )
    }

    func testExplicitTrafficTypeIsPassedToValidatorAsEventTypeAndTrafficType() {
        let tracker = makeTracker(defaultTrafficType: "user")

        let result = tracker.track(
            eventType: "purchase_event",
            trafficType: "account",
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertEqual(validator.lastEventTypeId, "purchase_event")
        XCTAssertEqual(validator.lastTrafficTypeName, "account")
    }

    func testDefaultTrafficTypeIsPassedToValidatorWhenNoneIsGiven() {
        let tracker = makeTracker(defaultTrafficType: "user")

        let result = tracker.track(
            eventType: "purchase_event",
            trafficType: nil,
            value: nil,
            properties: nil,
            matchingKey: "key1",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertEqual(validator.lastEventTypeId, "purchase_event")
        XCTAssertEqual(validator.lastTrafficTypeName, "user")
    }

    private func makeTracker(defaultTrafficType: String?) -> EventsTracker {
        DefaultEventsTracker(
            defaultTrafficType: defaultTrafficType,
            initialEventSizeInBytes: 1024,
            eventValidator: validator,
            propertyValidator: PropertyValidatorAdapterStub(stub: propertyValidator),
            logger: TrackerLoggerAdapterStub(),
            onEventPush: { _ in },
            onTrackLatency: nil
        )
    }
}

// Records the arguments the tracker hands to the event validator. Accepts every event.
fileprivate final class ArgumentRecordingEventValidator: TrackerEventValidator, @unchecked Sendable {
    private(set) var lastTrafficTypeName: String?
    private(set) var lastEventTypeId: String?

    func validate(key: String?,
                  trafficTypeName: String?,
                  eventTypeId: String?,
                  value: Double?,
                  properties: [String: Any]?,
                  isSdkReady: Bool) -> TrackerValidationError? {
        lastTrafficTypeName = trafficTypeName
        lastEventTypeId = eventTypeId
        return nil
    }
}

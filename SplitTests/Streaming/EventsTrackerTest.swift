//
//  EventsTrackerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventsTrackerTest: XCTestCase {
    var eventsTracker: EventsTracker!
    var synchronizer: SynchronizerStub!
    var telemetryProducer: TelemetryStorageStub!
    var propertyValidator: PropertyValidatorStub!

    override func setUp() {
        synchronizer = SynchronizerStub()
        telemetryProducer = TelemetryStorageStub()
        propertyValidator = PropertyValidatorStub()
        eventsTracker = DefaultEventsTracker(
            config: SplitClientConfig(),
            synchronizer: synchronizer,
            eventValidator: EventValidatorStub(),
            propertyValidator: propertyValidator,
            validationLogger: DefaultValidationMessageLogger(),
            telemetryProducer: telemetryProducer)
    }

    func testTrackEnabled() {
        trackingEnabledTest(enabled: true)
    }

    func testTrackDisabled() {
        trackingEnabledTest(enabled: false)
    }

    func testPropertiesValidation() {
        propertyValidator.validateResult = PropertyValidationResult.valid(
            properties: ["key1": "value1"],
            sizeInBytes: 100)

        let testProperties = ["test": "value", "number": 123] as [String: Any]

        let result = eventsTracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: 1.0,
            properties: testProperties,
            matchingKey: "test_key",
            isSdkReady: true)

        XCTAssertTrue(result)
        XCTAssertTrue(propertyValidator.validateCalled)
        XCTAssertEqual(
            propertyValidator.lastPropertiesValidated as? [String: String],
            testProperties as? [String: String])
        XCTAssertTrue(synchronizer.pushEventCalled)

        synchronizer.pushEventCalled = false
        propertyValidator.validateCalled = false

        propertyValidator.validateResult = PropertyValidationResult.invalid(
            message: "Properties too large",
            sizeInBytes: 50000)

        let invalidResult = eventsTracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: 1.0,
            properties: testProperties,
            matchingKey: "test_key",
            isSdkReady: true)

        XCTAssertFalse(invalidResult)
        XCTAssertTrue(propertyValidator.validateCalled)
        XCTAssertFalse(synchronizer.pushEventCalled)
    }

    func trackingEnabledTest(enabled: Bool) {
        eventsTracker.isTrackingEnabled = enabled
        let res = eventsTracker.track(
            eventType: "pepe",
            trafficType: "tt",
            value: nil,
            properties: nil,
            matchingKey: "the_key",
            isSdkReady: true)

        XCTAssertEqual(enabled, res)
        XCTAssertEqual(
            enabled ? 1 : -1,
            telemetryProducer.methodLatencies[.track] ?? -1)
        XCTAssertEqual(synchronizer.pushEventCalled, enabled)
    }
}

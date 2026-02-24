//
//  EventsTrackerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class EventsTrackerTest: XCTestCase {
    
    var eventsTracker: EventsTracker!
    var synchronizer: SynchronizerStub!
    var telemetryProducer: TelemetryStorageStub!
    var propertyValidator: PropertyValidatorStub!
    
    override func setUp() {
        synchronizer = SynchronizerStub()
        telemetryProducer = TelemetryStorageStub()
        propertyValidator = PropertyValidatorStub()
        let config = SplitClientConfig()
        eventsTracker = DefaultEventsTracker(
            defaultTrafficType: config.trafficType,
            initialEventSizeInBytes: config.initialEventSizeInBytes,
            eventValidator: EventValidatorAdapterStub(stub: EventValidatorStub()),
            propertyValidator: PropertyValidatorAdapterStub(stub: propertyValidator!),
            logger: TrackerLoggerAdapterStub(),
            onEventPush: { [weak self] event in
                self?.synchronizer.pushEvent(event: event.toEventDTO())
            },
            onTrackLatency: { [weak self] latency in
                self?.telemetryProducer?.recordLatency(method: .track, latency: latency)
            }
        )
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
            sizeInBytes: 100
        )

        let testProperties = ["test": "value", "number": 123] as [String: Any]

        let result = eventsTracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: 1.0,
            properties: testProperties,
            matchingKey: "test_key",
            isSdkReady: true
        )

        XCTAssertTrue(result)
        XCTAssertTrue(propertyValidator.validateCalled)
        XCTAssertEqual(propertyValidator.lastPropertiesValidated as? [String: String], testProperties as? [String: String])
        XCTAssertTrue(synchronizer.pushEventCalled)

        synchronizer.pushEventCalled = false
        propertyValidator.validateCalled = false

        propertyValidator.validateResult = PropertyValidationResult.invalid(
            message: "Properties too large",
            sizeInBytes: 50000
        )

        let invalidResult = eventsTracker.track(
            eventType: "test_event",
            trafficType: "test_tt",
            value: 1.0,
            properties: testProperties,
            matchingKey: "test_key",
            isSdkReady: true
        )

        XCTAssertFalse(invalidResult)
        XCTAssertTrue(propertyValidator.validateCalled)
        XCTAssertFalse(synchronizer.pushEventCalled)
    }

    func trackingEnabledTest(enabled: Bool) {
        eventsTracker.isTrackingEnabled = enabled
        let res = eventsTracker.track(eventType: "pepe",
                                      trafficType: "tt",
                                      value: nil,
                                      properties: nil,
                                      matchingKey: "the_key",
                                      isSdkReady: true)
        
        XCTAssertEqual(enabled, res)
        XCTAssertEqual(enabled ? 1 : -1
                       , telemetryProducer.methodLatencies[.track] ?? -1)
        XCTAssertEqual(synchronizer.pushEventCalled, enabled)
    }
}

// MARK: - Tracker Adapter Stubs for Tests

final class EventValidatorAdapterStub: TrackerEventValidator, @unchecked Sendable {
    private let stub: EventValidatorStub
    
    init(stub: EventValidatorStub) {
        self.stub = stub
    }
    
    func validate(key: String?,
                  trafficTypeName: String?,
                  eventTypeId: String?,
                  value: Double?,
                  properties: [String: Any]?,
                  isSdkReady: Bool) -> TrackerValidationError? {
        guard let errorInfo = stub.validate(key: key,
                                             trafficTypeName: trafficTypeName,
                                             eventTypeId: eventTypeId,
                                             value: value,
                                             properties: properties,
                                             isSdkReady: isSdkReady) else {
            return nil
        }
        return TrackerValidationError(isError: errorInfo.isError, message: errorInfo.errorMessage)
    }
}

final class PropertyValidatorAdapterStub: TrackerPropertyValidator, @unchecked Sendable {
    private let stub: PropertyValidatorStub
    
    init(stub: PropertyValidatorStub) {
        self.stub = stub
    }
    
    func validate(properties: [String: Any]?,
                  initialSizeInBytes: Int,
                  validationTag: String) -> TrackerPropertyResult {
        let result = stub.validate(properties: properties,
                                   initialSizeInBytes: initialSizeInBytes,
                                   validationTag: validationTag)
        return TrackerPropertyResult(isValid: result.isValid,
                                     validatedProperties: result.validatedProperties,
                                     sizeInBytes: result.sizeInBytes,
                                     errorMessage: result.errorMessage)
    }
}

final class TrackerLoggerAdapterStub: TrackerLogger, @unchecked Sendable {
    func log(errorInfo: TrackerValidationError, tag: String) {}
    func e(message: String, tag: String) {}
    func v(_ message: String) {}
}

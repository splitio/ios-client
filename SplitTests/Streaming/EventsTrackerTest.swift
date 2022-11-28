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

    override func setUp() {
        synchronizer = SynchronizerStub()
        telemetryProducer = TelemetryStorageStub()
        eventsTracker = DefaultEventsTracker(config: SplitClientConfig(),
                                             synchronizer: synchronizer,
                                             eventValidator: EventValidatorStub(),
                                             anyValueValidator: AnyValueValidatorStub(),
                                             validationLogger: DefaultValidationMessageLogger(),
                                             telemetryProducer: telemetryProducer)
    }

    func testTrackEnabled() {
        trackingEnabledTest(enabled: true)
    }

    func testTrackDisabled() {
        trackingEnabledTest(enabled: false)
    }

    func trackingEnabledTest(enabled: Bool) {
        eventsTracker.isTrackingEnabled = enabled
        let res = eventsTracker.track(eventType: "pepe",
                            trafficType: "tt",
                            value: nil,
                            properties: nil,
                            matchingKey: "the_key")

        XCTAssertEqual(enabled, res)
        XCTAssertEqual(enabled ? 1 : -1
                       , telemetryProducer.methodLatencies[.track] ?? -1)
        XCTAssertEqual(synchronizer.pushEventCalled, enabled)
    }
}


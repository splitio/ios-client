//
//  EventsRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class EventsRecorderWorkerTests: XCTestCase {
    var worker: EventsRecorderWorker!
    var eventStorage: PersistentEventsStorageStub!
    var eventsRecorder: HttpEventsRecorderStub!
    var dummyEvents = TestingHelper.createEvents(count: 11)

    override func setUp() {
        eventStorage = PersistentEventsStorageStub()
        eventsRecorder = HttpEventsRecorderStub()
        worker = EventsRecorderWorker(
            persistentEventsStorage: eventStorage,
            eventsRecorder: eventsRecorder,
            eventsPerPush: 2)
    }

    func testSendSuccess() {
        // Sent events have to be removed from storage
        for event in dummyEvents {
            eventStorage.push(event: event)
        }
        worker.flush()

        XCTAssertEqual(6, eventsRecorder.executeCallCount)
        XCTAssertEqual(11, eventsRecorder.eventsSent.count)
        XCTAssertEqual(0, eventStorage.storedEvents.count)
    }

    func testFailToSendSome() {
        // Sent events have to be removed from storage
        // Non sent have to appear as active in storage to try to send them again
        eventsRecorder.errorOccurredCallCount = 3
        for event in dummyEvents {
            eventStorage.push(event: event)
        }
        worker.flush()

        XCTAssertEqual(6, eventsRecorder.executeCallCount)
        XCTAssertEqual(2, eventStorage.storedEvents.count)
        XCTAssertEqual(9, eventsRecorder.eventsSent.count)
    }

    func testSendOneEvent() {
        eventStorage.push(event: dummyEvents[0])

        worker.flush()

        XCTAssertEqual(1, eventsRecorder.executeCallCount)
        XCTAssertEqual(0, eventStorage.storedEvents.count)
        XCTAssertEqual(1, eventsRecorder.eventsSent.count)
    }

    func testSendNoEvents() {
        // When no events available recorder should not be called
        worker.flush()

        XCTAssertEqual(0, eventsRecorder.executeCallCount)
        XCTAssertEqual(0, eventStorage.storedEvents.count)
        XCTAssertEqual(0, eventsRecorder.eventsSent.count)
    }

    override func tearDown() {}
}

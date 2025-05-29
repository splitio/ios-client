//
//  EventsSynchronizerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 30-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventsSynchronizerTest: XCTestCase {
    var periodicEventsRecorderWorker: PeriodicRecorderWorkerStub!
    var eventsRecorderWorker: RecorderWorkerStub!
    var synchronizer: EventsSynchronizer!
    var syncHelper: EventsRecorderSyncHelper!
    var telemetryProducer: TelemetryStorageStub!
    var syncWorkerFactory: SyncWorkerFactoryStub!

    override func setUp() {
        telemetryProducer = TelemetryStorageStub()
        syncWorkerFactory = SyncWorkerFactoryStub()
        periodicEventsRecorderWorker = PeriodicRecorderWorkerStub()
        eventsRecorderWorker = RecorderWorkerStub()
        syncWorkerFactory = SyncWorkerFactoryStub()

        syncWorkerFactory.periodicEventsRecorderWorker = periodicEventsRecorderWorker
        syncWorkerFactory.eventsRecorderWorker = eventsRecorderWorker

        syncHelper = EventsRecorderSyncHelper(
            eventsStorage: EventsStorageStub(),
            accumulator: DefaultRecorderFlushChecker(
                maxQueueSize: 10,
                maxQueueSizeInBytes: 10))
        synchronizer = DefaultEventsSynchronizer(
            syncWorkerFactory: syncWorkerFactory,
            eventsSyncHelper: syncHelper,
            telemetryProducer: telemetryProducer)
    }

    func testStart() {
        periodicEventsRecorderWorker.startCalled = false
        synchronizer.start()

        XCTAssertTrue(periodicEventsRecorderWorker.startCalled)
    }

    func testStop() {
        periodicEventsRecorderWorker.stopCalled = false
        synchronizer.stop()

        XCTAssertTrue(periodicEventsRecorderWorker.stopCalled)
    }

    func testPause() {
        periodicEventsRecorderWorker.pauseCalled = false
        synchronizer.pause()

        XCTAssertTrue(periodicEventsRecorderWorker.pauseCalled)
    }

    func testResume() {
        periodicEventsRecorderWorker.resumeCalled = false
        synchronizer.resume()

        XCTAssertTrue(periodicEventsRecorderWorker.resumeCalled)
    }

    func testPush() {
        for i in 0 ..< 5 {
            synchronizer.push(EventDTO(trafficType: "t1", eventType: "e\(i)"))
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(5, telemetryProducer.events[.queued])
    }

    func testFlush() {
        eventsRecorderWorker.flushCalled = false
        synchronizer.flush()

        XCTAssertTrue(eventsRecorderWorker.flushCalled)
    }

    func testDestroy() {
        periodicEventsRecorderWorker.destroyCalled = false
        synchronizer.destroy()

        XCTAssertTrue(periodicEventsRecorderWorker.destroyCalled)
    }
}

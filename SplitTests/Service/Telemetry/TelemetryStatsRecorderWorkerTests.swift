//
//  TelemetryStatsRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class TelemetryStatsRecorderWorkerTests: XCTestCase {
    var worker: TelemetryStatsRecorderWorker!
    var statsRecorder: HttpTelemetryStatsRecorderStub!
    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: MySegmentsStorageStub!
    var myLargeSegmentsStorage: MySegmentsStorageStub!
    var telemetryStorage: TelemetryStorageStub!

    override func setUp() {
        statsRecorder = HttpTelemetryStatsRecorderStub()
        telemetryStorage = TelemetryStorageStub()
        mySegmentsStorage = MySegmentsStorageStub()
        myLargeSegmentsStorage = MySegmentsStorageStub()
        splitsStorage = SplitsStorageStub()

        worker = TelemetryStatsRecorderWorker(
            telemetryStatsRecorder: statsRecorder,
            telemetryConsumer: telemetryStorage,
            splitsStorage: splitsStorage,
            mySegmentsStorage: mySegmentsStorage,
            myLargeSegmentsStorage: myLargeSegmentsStorage)
    }

    func testSendSuccess() {
        worker.flush()

        XCTAssertEqual(1, statsRecorder.executeCallCount)
        XCTAssertNotNil(statsRecorder.statsSent)
        XCTAssertEqual(1, splitsStorage.getCountCalledCount)
        XCTAssertEqual(1, mySegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, myLargeSegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, telemetryStorage.popTagsCallCount)
    }

    func testFailedAttemptLimit() {
        statsRecorder.errorOccurredCallCount = 3

        worker.flush()

        XCTAssertEqual(3, statsRecorder.executeCallCount)
        XCTAssertEqual(1, splitsStorage.getCountCalledCount)
        XCTAssertEqual(1, mySegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, myLargeSegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, telemetryStorage.popTagsCallCount)
    }

    func testFailedAttemptLimitExceded() {
        statsRecorder.errorOccurredCallCount = 10

        worker.flush()

        XCTAssertEqual(3, statsRecorder.executeCallCount)
        XCTAssertEqual(1, splitsStorage.getCountCalledCount)
        XCTAssertEqual(1, mySegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, myLargeSegmentsStorage.getCountCalledCount)
        XCTAssertEqual(1, telemetryStorage.popTagsCallCount)
    }

    func testEndpointNotReachable() {
        statsRecorder.errorOccurredCallCount = 1
        statsRecorder.endpointAvailable = false

        worker.flush()

        XCTAssertEqual(0, statsRecorder.executeCallCount)
        XCTAssertEqual(0, splitsStorage.getCountCalledCount)
        XCTAssertEqual(0, mySegmentsStorage.getCountCalledCount)
        XCTAssertEqual(0, myLargeSegmentsStorage.getCountCalledCount)
        XCTAssertEqual(0, telemetryStorage.popTagsCallCount)
    }

    func recordTelemetryForTest() {
        telemetryStorage.recordSessionLength(sessionLength: 10000)
        telemetryStorage.addTag(tag: "pepe")
    }

    func testConcurrentFlush() {
        statsRecorder.queue = DispatchQueue(label: "pepe")
        let queue = DispatchQueue(label: "concurrent-test", attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0 ..< 6 {
            group.enter()
            queue.async {
                self.worker.flush()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertEqual(6, self.statsRecorder.executeCallCount)
            XCTAssertNotNil(self.statsRecorder.statsSent)
            XCTAssertEqual(6, self.splitsStorage.getCountCalledCount)
            XCTAssertEqual(6, self.mySegmentsStorage.getCountCalledCount)
            XCTAssertEqual(6, self.myLargeSegmentsStorage.getCountCalledCount)
            XCTAssertEqual(6, self.telemetryStorage.popTagsCallCount)
        }
    }
}

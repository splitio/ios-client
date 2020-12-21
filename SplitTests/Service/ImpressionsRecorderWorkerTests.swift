//
//  ImpressionsRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class ImpressionsRecorderWorkerTests: XCTestCase {

    var worker: ImpressionsRecorderWorker!
    var impressionStorage: PersistentImpressionsStorageStub!
    var impressionsRecorder: HttpImpressionsRecorderStub!
    var dummyImpressions = TestingHelper.createImpressions(count: 11)

    override func setUp() {
        impressionStorage = PersistentImpressionsStorageStub()
        impressionsRecorder = HttpImpressionsRecorderStub()
        worker = ImpressionsRecorderWorker(impressionsStorage: impressionStorage,
                                      impressionsRecorder: impressionsRecorder,
                                      impressionsPerPush: 2)
    }

    func testSendSuccess() {
        // Sent impressions have to be removed from storage
        for impression in dummyImpressions {
            impressionStorage.push(impression: impression)
        }
        worker.flush()

        XCTAssertEqual(6, impressionsRecorder.executeCallCount)
        XCTAssertEqual(11, impressionsRecorder.impressionsSent.count)
        XCTAssertEqual(0, impressionStorage.storedImpressions.count)
    }

    func testFailToSendSome() {
        // Sent impressions have to be removed from storage
        // Non sent have to appear as active in storage to try to send them again
        impressionsRecorder.errorOccurredCallCount = 3
        for impression in dummyImpressions {
            impressionStorage.push(impression: impression)
        }
        worker.flush()

        XCTAssertEqual(6, impressionsRecorder.executeCallCount)
        XCTAssertEqual(2, impressionStorage.storedImpressions.count)
        XCTAssertEqual(9, impressionsRecorder.impressionsSent.count)
    }

    func testSendOneImpression() {
        impressionStorage.push(impression: dummyImpressions[0])

        worker.flush()

        XCTAssertEqual(1, impressionsRecorder.executeCallCount)
        XCTAssertEqual(0, impressionStorage.storedImpressions.count)
        XCTAssertEqual(1, impressionsRecorder.impressionsSent.count)
    }


    func testSendNoImpressions() {
        // When no impressions available recorder should not be called
        worker.flush()

        XCTAssertEqual(0, impressionsRecorder.executeCallCount)
        XCTAssertEqual(0, impressionStorage.storedImpressions.count)
        XCTAssertEqual(0, impressionsRecorder.impressionsSent.count)
    }

    override func tearDown() {
    }
}


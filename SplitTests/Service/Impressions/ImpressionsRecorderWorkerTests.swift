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
    var persistentImpressionStorage: PersistentImpressionsStorageStub!
    var impressionsRecorder: HttpImpressionsRecorderStub!
    var dummyImpressions: [KeyImpression]!


    override func setUp() {
        dummyImpressions = TestingHelper.createKeyImpressions(count: 5)
        dummyImpressions.append(contentsOf: TestingHelper.createKeyImpressions(feature: "split1", count: 6))
        persistentImpressionStorage = PersistentImpressionsStorageStub()
        impressionsRecorder = HttpImpressionsRecorderStub()
        worker = ImpressionsRecorderWorker(persistentImpressionsStorage: persistentImpressionStorage,
                                      impressionsRecorder: impressionsRecorder,
                                      impressionsPerPush: 2)
    }

    func testSendSuccess() {
        // Sent impressions have to be removed from storage
        for impression in dummyImpressions {
            persistentImpressionStorage.push(impression: impression)
        }
        worker.flush()

        XCTAssertEqual(6, impressionsRecorder.executeCallCount)
        XCTAssertEqual(11, impressionsRecorder.impressionsSent.flatMap { $0.keyImpressions }.count)
        XCTAssertEqual(0, persistentImpressionStorage.storedImpressions.count)
    }

    func testFailToSendSome() {
        // Sent impressions have to be removed from storage.
        // The flush stops on the first failed batch; impressions from that batch and
        // all subsequent ones remain in storage (still active, recoverable on next flush).
        impressionsRecorder.errorOccurredCallCount = 3
        for impression in dummyImpressions {
            persistentImpressionStorage.push(impression: impression)
        }
        worker.flush()

        // 11 impressions / 2 per push → 3 execute calls before the error:
        //   call 1 (ok): 2 sent, deleted. call 2 (ok): 2 sent, deleted.
        //   call 3 (error): loop breaks, 2 + 5 remaining = 7 still in storage.
        XCTAssertEqual(3, impressionsRecorder.executeCallCount)
        XCTAssertEqual(7, persistentImpressionStorage.storedImpressions.count)
        XCTAssertEqual(4, impressionsRecorder.impressionsSent.flatMap { $0.keyImpressions }.count)
    }

    func testSendOneImpression() {
        persistentImpressionStorage.push(impression: dummyImpressions[0])

        worker.flush()

        XCTAssertEqual(1, impressionsRecorder.executeCallCount)
        XCTAssertEqual(0, persistentImpressionStorage.storedImpressions.count)
        XCTAssertEqual(1, impressionsRecorder.impressionsSent.count)
    }


    func testSendNoImpressions() {
        // When no impressions available recorder should not be called
        worker.flush()

        XCTAssertEqual(0, impressionsRecorder.executeCallCount)
        XCTAssertEqual(0, persistentImpressionStorage.storedImpressions.count)
        XCTAssertEqual(0, impressionsRecorder.impressionsSent.count)
    }

    override func tearDown() {
    }
}


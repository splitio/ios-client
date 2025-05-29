//
//  ImpressionsRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

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
        worker = ImpressionsRecorderWorker(
            persistentImpressionsStorage: persistentImpressionStorage,
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
        // Sent impressions have to be removed from storage
        // Non sent have to appear as active in storage to try to send them again
        impressionsRecorder.errorOccurredCallCount = 3
        for impression in dummyImpressions {
            persistentImpressionStorage.push(impression: impression)
        }
        worker.flush()

        XCTAssertEqual(6, impressionsRecorder.executeCallCount)
        XCTAssertEqual(2, persistentImpressionStorage.storedImpressions.count)
        XCTAssertEqual(9, impressionsRecorder.impressionsSent.flatMap { $0.keyImpressions }.count)
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

    override func tearDown() {}
}

//
//  ImpressionsCountRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-06-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class CountsRecorderCountWorkerTests: XCTestCase {
    var worker: ImpressionsCountRecorderWorker!
    var countsStorage: PersistentImpressionsCountStorageStub!
    var countsRecorder: HttpImpressionsCountRecorderStub!
    var dummyCounts: [ImpressionsCountPerFeature]!

    override func setUp() {
        dummyCounts = TestingHelper.createImpressionsCount(count: 601)
        countsStorage = PersistentImpressionsCountStorageStub()
        countsRecorder = HttpImpressionsCountRecorderStub()
        worker = ImpressionsCountRecorderWorker(countsStorage: countsStorage, countsRecorder: countsRecorder)
    }

    func testSendSuccess() {
        // Sent impressions have to be removed from storage
        for count in dummyCounts {
            countsStorage.push(count: count)
        }
        worker.flush()

        XCTAssertEqual(4, countsRecorder.executeCallCount)
        XCTAssertEqual(601, countsRecorder.countsSent.count)
        XCTAssertEqual(0, countsStorage.storedImpressions.count)
    }

    func testFailToSendSome() {
        // Sent impressions count have to be removed from storage
        // Non sent have to appear as active in storage to try to send them again
        countsRecorder.errorOccurredCallCount = 3
        for impression in dummyCounts {
            countsStorage.push(count: impression)
        }
        worker.flush()

        XCTAssertEqual(4, countsRecorder.executeCallCount)
        XCTAssertEqual(200, countsStorage.storedImpressions.count)
        XCTAssertEqual(401, countsRecorder.countsSent.count)
    }

    func testSendOneImpression() {
        countsStorage.push(count: dummyCounts[0])

        worker.flush()

        XCTAssertEqual(1, countsRecorder.executeCallCount)
        XCTAssertEqual(0, countsStorage.storedImpressions.count)
        XCTAssertEqual(1, countsRecorder.countsSent.count)
    }

    func testSendNoImpressions() {
        // When no impressions available recorder should not be called
        worker.flush()

        XCTAssertEqual(0, countsRecorder.executeCallCount)
        XCTAssertEqual(0, countsStorage.storedImpressions.count)
        XCTAssertEqual(0, countsRecorder.countsSent.count)
    }

    override func tearDown() {}
}

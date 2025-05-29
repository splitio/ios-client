//
//  UniqueKeysRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-06-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class UniqueKeysRecorderCountWorkerTests: XCTestCase {
    var worker: UniqueKeysRecorderWorker!
    var keysStorage: PersistentUniqueKeyStorageStub!
    var keysRecorder: HttpUniqueKeysRecorderStub!
    var dummyKeys = [UniqueKey]()

    override func setUp() {
        dummyKeys = TestingHelper.createUniqueKeys(keyCount: 60, featureCount: 30).keys
        keysStorage = PersistentUniqueKeyStorageStub()
        keysRecorder = HttpUniqueKeysRecorderStub()
        worker = UniqueKeysRecorderWorker(
            uniqueKeyStorage: keysStorage,
            uniqueKeysRecorder: keysRecorder)
    }

    func testSendSuccess() {
        // Sent impressions have to be removed from storage
        keysStorage.pushMany(keys: dummyKeys)
        worker.flush()

        XCTAssertEqual(2, keysRecorder.executeCallCount)
        XCTAssertEqual(60, keysRecorder.keysSent.count)
        XCTAssertEqual(0, keysStorage.uniqueKeys.count)
    }

    func testFailToSendSome() {
        // Sent impressions count have to be removed from storage
        // Non sent have to appear as active in storage to try to send them again
        keysRecorder.errorOccurredCallCount = 2
        keysStorage.pushMany(keys: dummyKeys)
        worker.flush()

        XCTAssertEqual(2, keysRecorder.executeCallCount)
        XCTAssertEqual(10, keysStorage.uniqueKeys.count)
        XCTAssertEqual(50, keysRecorder.keysSent.count)
    }

    func testSendOneImpression() {
        dummyKeys = TestingHelper.createUniqueKeys(keyCount: 1, featureCount: 10).keys
        keysStorage.pushMany(keys: dummyKeys)

        worker.flush()

        XCTAssertEqual(1, keysRecorder.executeCallCount)
        XCTAssertEqual(0, keysStorage.uniqueKeys.count)
        XCTAssertEqual(1, keysRecorder.keysSent.count)
    }

    func testSendNoImpressions() {
        // When no impressions available recorder should not be called
        worker.flush()

        XCTAssertEqual(0, keysRecorder.executeCallCount)
        XCTAssertEqual(0, keysStorage.uniqueKeys.count)
        XCTAssertEqual(0, keysRecorder.keysSent.count)
    }

    override func tearDown() {}
}

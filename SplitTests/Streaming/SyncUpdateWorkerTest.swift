//
//  SyncUpdateWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SyncUpdateWorker: XCTestCase {


    var splitsUpdateWorker: SplitsUpdateWorker!
    var mySegmentsUpdateWorker: MySegmentsUpdateWorker!
    var splitKillWorker: SplitKillWorker!

    var synchronizer: SynchronizerStub!
    var splitCache: SplitCacheStub!
    var mySegmentsCache: MySegmentsCacheStub!

    override func setUp() {
        synchronizer = SynchronizerStub()
        splitCache = SplitCacheStub(splits: [Split](), changeNumber: 100)
        mySegmentsCache = MySegmentsCacheStub()

        splitsUpdateWorker = SplitsUpdateWorker(synchronizer: synchronizer)
        mySegmentsUpdateWorker =  MySegmentsUpdateWorker(synchronizer: synchronizer, mySegmentsCache: mySegmentsCache)
        splitKillWorker = SplitKillWorker(synchronizer: synchronizer, splitCache: splitCache)
    }

    func testSplitUpdateWorker() throws {
        let notification = SplitsUpdateNotification(type: .splitUpdate, changeNumber: -1)
        let exp = XCTestExpectation(description: "exp")
        synchronizer.syncSplitsChangeNumberExp = exp

        try splitsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)
        XCTAssertTrue(synchronizer.synchronizeSplitsChangeNumberCalled)
    }

    func testSplitKillWorker() throws {
        let notification = SplitKillNotification(type: .splitKill,
                                                 changeNumber: 100,
                                                 splitName: "split1",
                                                 defaultTreatment: "off")

        let exp = XCTestExpectation(description: "exp")
        let exp1 = XCTestExpectation(description: "exp1")
        synchronizer.syncSplitsChangeNumberExp = exp
        splitCache.killExpectation = exp1


        try splitKillWorker.process(notification: notification)

        wait(for: [exp, exp1], timeout: 3)

        XCTAssertEqual("split1", splitCache.killedSplit?.name)
        XCTAssertEqual("off", splitCache.killedSplit?.defaultTreatment)
        XCTAssertEqual(100, splitCache.killedSplit?.changeNumber)
        XCTAssertTrue(synchronizer.synchronizeSplitsChangeNumberCalled)
    }

    func testMySegmentsUpdateWorkerWithPayload() throws {
        let notification = MySegmentsUpdateNotification(type: .mySegmentsUpdate,
                                                        changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: ["s1", "s2"])

        let exp = XCTestExpectation(description: "exp")
        mySegmentsCache.updateExpectation = exp


        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(2, mySegmentsCache.updatedSegments?.count)
        XCTAssertEqual(1, mySegmentsCache.updatedSegments?.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegmentsCache.updatedSegments?.filter { $0 == "s2" }.count)
        XCTAssertFalse(mySegmentsCache.clearCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerWithPayloadNil() throws {
        let notification = MySegmentsUpdateNotification(type: .mySegmentsUpdate,
                                                        changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: nil)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsCache.clearExpectation = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertNil(mySegmentsCache.updatedSegments)
        XCTAssertTrue(mySegmentsCache.clearCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerNoPayload() throws {
        let notification = MySegmentsUpdateNotification(type: .mySegmentsUpdate,
                                                        changeNumber: 100,
                                                        includesPayload: false,
                                                        segmentList: nil)

        let exp = XCTestExpectation(description: "exp")
        synchronizer.syncMySegmentsExp = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertNil(mySegmentsCache.updatedSegments)
        XCTAssertFalse(mySegmentsCache.clearCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
    }

    override func tearDown() {

    }
}

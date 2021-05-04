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
    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: MySegmentsStorageStub!
    var mySegmentsChangesChecker: MySegmentsChangesCheckerMock!

    override func setUp() {
        synchronizer = SynchronizerStub()
        splitsStorage = SplitsStorageStub()
        mySegmentsChangesChecker = MySegmentsChangesCheckerMock()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "split1")],
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        mySegmentsStorage = MySegmentsStorageStub()

        splitsUpdateWorker = SplitsUpdateWorker(synchronizer: synchronizer)

        mySegmentsUpdateWorker =  MySegmentsUpdateWorker(synchronizer: synchronizer, mySegmentsStorage: mySegmentsStorage)
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker
        splitKillWorker = SplitKillWorker(synchronizer: synchronizer, splitsStorage: splitsStorage)
    }

    func testSplitUpdateWorker() throws {
        let notification = SplitsUpdateNotification(changeNumber: -1)
        let exp = XCTestExpectation(description: "exp")
        synchronizer.syncSplitsChangeNumberExp = exp

        try splitsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)
        XCTAssertTrue(synchronizer.synchronizeSplitsChangeNumberCalled)
    }

    func testSplitKillWorker() throws {
        let notification = SplitKillNotification(changeNumber: 100,
                                                 splitName: "split1",
                                                 defaultTreatment: "off")

        let exp = XCTestExpectation(description: "exp")
        let exp1 = XCTestExpectation(description: "exp1")
        synchronizer.syncSplitsChangeNumberExp = exp
        splitsStorage.updatedWithoutChecksExp = exp1


        try splitKillWorker.process(notification: notification)

        wait(for: [exp, exp1], timeout: 3)

        XCTAssertEqual("split1", splitsStorage.updatedWithoutChecksSplit?.name)
        XCTAssertEqual("off", splitsStorage.updatedWithoutChecksSplit?.defaultTreatment)
        XCTAssertEqual(100, splitsStorage.updatedWithoutChecksSplit?.changeNumber)
        XCTAssertTrue(synchronizer.synchronizeSplitsChangeNumberCalled)
    }

    func testMySegmentsUpdateWorkerWithPayloadChanged() throws {


        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: ["s1", "s2"])

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.updateExpectation = exp
        mySegmentsChangesChecker.haveChanged = true
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker
        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(2, mySegmentsStorage.updatedSegments?.count)
        XCTAssertEqual(1, mySegmentsStorage.updatedSegments?.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegmentsStorage.updatedSegments?.filter { $0 == "s2" }.count)
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.notifyMySegmentsUpdatedCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerWithPayloadWithoutChanges() throws {


        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: ["s1", "s2"])

        mySegmentsChangesChecker.haveChanged = false
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker
        try mySegmentsUpdateWorker.process(notification: notification)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertFalse(synchronizer.notifyMySegmentsUpdatedCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerWithPayloadNil() throws {
        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: nil)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.clearExpectation = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertTrue(mySegmentsStorage.clearCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerNoPayload() throws {
        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: false,
                                                        segmentList: nil)

        let exp = XCTestExpectation(description: "exp")
        synchronizer.forceMySegmentsSyncExp = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.forceMySegmentsSyncCalled)
    }

    override func tearDown() {

    }
}

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

class SyncUpdateWorkerTest: XCTestCase {

    var splitsUpdateWorker: SplitsUpdateWorker!
    var mySegmentsUpdateWorker: MySegmentsUpdateWorker!
    var mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker!
    var myLargeSegmentsUpdateWorker: MyLargeSegmentsUpdateWorker!
    var splitKillWorker: SplitKillWorker!

    var segmentsUpdateWorkerHelper: SegmentsUpdateWorkerHelperMock!
    var largeSegmentsUpdateWorkerHelper: SegmentsUpdateWorkerHelperMock!
    var synchronizer: SynchronizerStub!
    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: MySegmentsStorageStub!
    var mySegmentsChangesChecker: MySegmentsChangesCheckerMock!
    var mySegmentsPayloadDecoder: MySegmentsV2PayloadDecoderMock!
    let userKey = IntegrationHelper.dummyUserKey
    var userKeyHash: String = ""
    var telemetryProducer: TelemetryStorageStub!
    var splitChangeProcessor: SplitChangeProcessorStub!

    override func setUp() {
        userKeyHash = DefaultMySegmentsPayloadDecoder().hash(userKey: userKey)
        synchronizer = SynchronizerStub()
        splitsStorage = SplitsStorageStub()
        mySegmentsChangesChecker = MySegmentsChangesCheckerMock()
        mySegmentsPayloadDecoder = MySegmentsV2PayloadDecoderMock()
        telemetryProducer = TelemetryStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "split1")],
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        mySegmentsStorage = MySegmentsStorageStub()
        mySegmentsStorage.segments[userKey] = []
        splitChangeProcessor = SplitChangeProcessorStub()
        splitsUpdateWorker = SplitsUpdateWorker(synchronizer: synchronizer,
                                                splitsStorage: splitsStorage,
                                                splitChangeProcessor: splitChangeProcessor,
                                                featureFlagsPayloadDecoder: FeatureFlagsPayloadDecoderMock(),
                                                telemetryProducer: telemetryProducer)

        mySegmentsUpdateWorker =  MySegmentsUpdateWorker(synchronizer: synchronizer,
                                                         mySegmentsStorage: mySegmentsStorage,
                                                         mySegmentsPayloadDecoder: DefaultMySegmentsPayloadDecoder())
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker

        segmentsUpdateWorkerHelper =  SegmentsUpdateWorkerHelperMock()
        mySegmentsUpdateV2Worker =  MySegmentsUpdateV2Worker(helper: segmentsUpdateWorkerHelper)
        
        largeSegmentsUpdateWorkerHelper =  SegmentsUpdateWorkerHelperMock()
        myLargeSegmentsUpdateWorker =  MyLargeSegmentsUpdateWorker(helper: largeSegmentsUpdateWorkerHelper)

        splitKillWorker = SplitKillWorker(synchronizer: synchronizer, splitsStorage: splitsStorage)
    }

    func testSplitUpdateWorkerNoPayload() throws {
        splitsStorage.changeNumber = 10
        let notification = SplitsUpdateNotification(changeNumber: 100)
        let exp = XCTestExpectation(description: "exp")
        synchronizer.syncSplitsChangeNumberExp = exp

        try splitsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)
        XCTAssertTrue(synchronizer.synchronizeSplitsChangeNumberCalled)
        XCTAssertFalse(telemetryProducer.recordSessionLengthCalled)
    }

    func testSplitUpdateWorkerWithPayloadChangeNumberBigger() throws {
        let exp = XCTestExpectation()
        telemetryProducer.recordUpdatesFromSseExp = exp
        splitsStorage.changeNumber = 10
        let notification = SplitsUpdateNotification(changeNumber: 100,
                                                    previousChangeNumber: 10,
                                                    definition: "fake_definition",
                                                    compressionType: .gzip)

        try splitsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 5)

        XCTAssertTrue(splitsStorage.updateSplitChangeCalled)
        XCTAssertEqual(10, splitChangeProcessor.splitChange?.since)
        XCTAssertEqual(100, splitChangeProcessor.splitChange?.till)
        XCTAssertEqual(1, splitChangeProcessor.splitChange?.splits.count)
        XCTAssertTrue(telemetryProducer.recordUpdatesFromSseCalled)
        XCTAssertFalse(synchronizer.synchronizeSplitsChangeNumberCalled)
    }

    func testSplitUpdateWorkerWithPayloadChangeNumberSmaller() throws {

        splitsStorage.changeNumber = 1000
        splitsStorage.updateSplitChangeCalled = false
        let notification = SplitsUpdateNotification(changeNumber: 100,
                                                    previousChangeNumber: 10,
                                                    definition: "fake_definition",
                                                    compressionType: .gzip)

        try splitsUpdateWorker.process(notification: notification)

        XCTAssertFalse(splitsStorage.updateSplitChangeCalled)
        XCTAssertNil(splitChangeProcessor.splitChange)
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
        XCTAssertFalse(synchronizer.synchronizeSplitsChangeNumberCalled)
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
                                                        segmentList: ["s1", "s2"],
                                                        userKeyHash: userKeyHash)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.updateExpectation[userKey] = exp
        mySegmentsChangesChecker.haveChanged = true
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker
        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(2, mySegmentsStorage.segments[userKey]?.count)
        XCTAssertEqual(1, mySegmentsStorage.segments[userKey]?.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegmentsStorage.segments[userKey]?.filter { $0 == "s2" }.count)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(synchronizer.notifySegmentsUpdatedForKeyCalled[userKey] ?? false)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsForKeyCalled[userKey] ?? false)
    }

    func testMySegmentsUpdateWorkerWithPayloadWithoutChanges() throws {


        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: ["s1", "s2"],
                                                        userKeyHash: userKeyHash)

        mySegmentsChangesChecker.haveChanged = false
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker
        try mySegmentsUpdateWorker.process(notification: notification)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(synchronizer.notifyMySegmentsUpdatedCalled)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerWithPayloadNil() throws {
        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: true,
                                                        segmentList: nil,
                                                        userKeyHash: userKeyHash)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.clearExpectation[userKey] = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertTrue(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertFalse(synchronizer.synchronizeMySegmentsCalled)
    }

    func testMySegmentsUpdateWorkerNoPayload() throws {
        let notification = MySegmentsUpdateNotification(changeNumber: 100,
                                                        includesPayload: false,
                                                        segmentList: nil,
                                                        userKeyHash: userKeyHash)

        let exp = XCTestExpectation(description: "exp")
        synchronizer.forceMySegmentsSyncExp[userKey] = exp

        try mySegmentsUpdateWorker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(synchronizer.forceMySegmentsSyncForKeyCalled[userKey] ?? false)
    }

    func testMySegmentsUpdateV2WorkerUnbounded() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .unboundedFetchRequest,
                                                          segmentName: nil, data: nil)

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }

    func testMySegmentsUpdateV2WorkerRemoval() throws {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "s3", data: nil)

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }

    func testMySegmentsUpdateV2WorkerNonRemoval() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "not_in_segments", data: nil)

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }

    func testMySegmentsUpdateV2KeyListRemove() throws {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s3", data: "some data")

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }

    func testMySegmentsUpdateV2KeyLisAdd() throws {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")

                mySegmentsUpdateV2Worker =  MySegmentsUpdateV2Worker(helper: segmentsUpdateWorkerHelper)

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }

    func testMySegmentsUpdateV2KeyListNoAction() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")

        try mySegmentsUpdateV2Worker.process(notification: notification)

        XCTAssertTrue(segmentsUpdateWorkerHelper.processCalled)
    }
}

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
    var mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker!
    var splitKillWorker: SplitKillWorker!

    var synchronizer: SynchronizerStub!
    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: OneKeyMySegmentsStorageStub!
    var mySegmentsChangesChecker: MySegmentsChangesCheckerMock!
    var mySegmentsPayloadDecoder: MySegmentsV2PayloadDecoderMock!
    let userKey = IntegrationHelper.dummyUserKey

    override func setUp() {
        synchronizer = SynchronizerStub()
        splitsStorage = SplitsStorageStub()
        mySegmentsChangesChecker = MySegmentsChangesCheckerMock()
        mySegmentsPayloadDecoder = MySegmentsV2PayloadDecoderMock()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "split1")],
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        mySegmentsStorage = OneKeyMySegmentsStorageStub()

        splitsUpdateWorker = SplitsUpdateWorker(synchronizer: synchronizer)

        mySegmentsUpdateWorker =  MySegmentsUpdateWorker(synchronizer: synchronizer, mySegmentsStorage: mySegmentsStorage)
        mySegmentsUpdateWorker.changesChecker = mySegmentsChangesChecker

        mySegmentsUpdateV2Worker =  MySegmentsUpdateV2Worker(userKey: userKey,
                                                             synchronizer: synchronizer,
                                                             mySegmentsStorage: mySegmentsStorage,
                                                             payloadDecoder: mySegmentsPayloadDecoder)
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

    func testMySegmentsUpdateV2WorkerUnbounded() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .unboundedFetchRequest,
                                                          segmentName: nil, data: nil)

        let exp = XCTestExpectation(description: "exp")
        synchronizer.forceMySegmentsSyncExp = exp

        try mySegmentsUpdateV2Worker.process(notification: notification)

        wait(for: [exp], timeout: 3)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.forceMySegmentsSyncCalled)
    }

    func testMySegmentsUpdateV2WorkerRemoval() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "s3", data: nil)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.updateExpectation = exp

        try mySegmentsUpdateV2Worker.process(notification: notification)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2"], mySegmentsStorage.updatedSegments?.sorted())
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.notifyMySegmentsUpdatedCalled)
    }

    func testMySegmentsUpdateV2WorkerNonRemoval() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "not_in_segments", data: nil)

        try mySegmentsUpdateV2Worker.process(notification: notification)
        ThreadUtils.delay(seconds: 2)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertFalse(synchronizer.notifyMySegmentsUpdatedCalled)
    }

    func testMySegmentsUpdateV2KeyListRemove() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s3", data: "some data")

        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [4, 5], removed: [keyHash, 3])

        mySegmentsUpdateV2Worker =  MySegmentsUpdateV2Worker(userKey: userKey,
                                                             synchronizer: synchronizer,
                                                             mySegmentsStorage: mySegmentsStorage,
                                                             payloadDecoder: mySegmentsPayloadDecoder)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.updateExpectation = exp

        try mySegmentsUpdateV2Worker.process(notification: notification)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2"], mySegmentsStorage.updatedSegments?.sorted())
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.notifyMySegmentsUpdatedCalled)
    }

    func testMySegmentsUpdateV2KeyLisAdd() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")

        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [keyHash, 5], removed: [1, 3])

        mySegmentsUpdateV2Worker =  MySegmentsUpdateV2Worker(userKey: userKey,
                                                             synchronizer: synchronizer,
                                                             mySegmentsStorage: mySegmentsStorage,
                                                             payloadDecoder: mySegmentsPayloadDecoder)

        let exp = XCTestExpectation(description: "exp")
        mySegmentsStorage.updateExpectation = exp

        try mySegmentsUpdateV2Worker.process(notification: notification)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2", "s3", "s5"], mySegmentsStorage.updatedSegments?.sorted())
        XCTAssertFalse(mySegmentsStorage.clearCalled)
        XCTAssertTrue(synchronizer.notifyMySegmentsUpdatedCalled)
    }

    func testMySegmentsUpdateV2KeyListNoAction() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")

        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [6, 5], removed: [1, 3])

        try mySegmentsUpdateV2Worker.process(notification: notification)

        ThreadUtils.delay(seconds: 1)

        XCTAssertNil(mySegmentsStorage.updatedSegments)
        XCTAssertFalse(synchronizer.notifyMySegmentsUpdatedCalled)
    }

    override func tearDown() {

    }
}

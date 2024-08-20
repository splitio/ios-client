//
//  SegmentsUpdateWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SegmentsUpdateWorkerHelperTests: XCTestCase {

    var helper: SegmentsUpdateWorkerHelper!
    var synchronizer: SynchronizerStub!
    var mySegmentsStorage: MySegmentsStorageStub!
    var mySegmentsChangesChecker: MySegmentsChangesCheckerMock!
    var mySegmentsPayloadDecoder: MySegmentsV2PayloadDecoderMock!
    let userKey = IntegrationHelper.dummyUserKey
    var userKeyHash: String = ""
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        userKeyHash = DefaultMySegmentsPayloadDecoder().hash(userKey: userKey)
        synchronizer = SynchronizerStub()
        mySegmentsChangesChecker = MySegmentsChangesCheckerMock()
        mySegmentsPayloadDecoder = MySegmentsV2PayloadDecoderMock()
        telemetryProducer = TelemetryStorageStub()
        mySegmentsStorage = MySegmentsStorageStub()
        mySegmentsStorage.segments[userKey] = []
    }

    func testUnboundedMySegmentsV2() throws {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .unboundedFetchRequest,
                                                          segmentName: nil, data: nil)
        unboundedTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testUnboundedMyLargeSegments() throws {
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .none,
                                                             updateStrategy: .unboundedFetchRequest,
                                                             largeSegments: nil, data: nil,
                                                             hash: nil, seed: nil, timeMillis: 500)
        unboundedTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func unboundedTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType, delay: Int64 = 0) {

        let exp = expFetchResource(resource)

        helperFor(resource: resource).process(info)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(forceSyncCalled(resource, forKey: userKey))
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testMySegmentsRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "s3", data: nil)
        segmentsRemovalTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testMyLargeSegmentsRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .none,
                                                             updateStrategy: .segmentRemoval,
                                                             largeSegments: ["s3"], data: nil,
                                                             hash: nil, seed: nil, timeMillis: 500)
        segmentsRemovalTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func segmentsRemovalTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType) {
        let exp = expForResource(resource)

        helperFor(resource: resource).process(info)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2"], mySegmentsStorage.segments[userKey]?.sorted())
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(updateNotified(resource, forKey: userKey))
        XCTAssertTrue(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testMySegmentsNonRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .none,
                                                          updateStrategy: .segmentRemoval,
                                                          segmentName: "not_in_segments", data: nil)
        segmentsNonRemovalTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testMyLargeSegmentsNonRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .none,
                                                             updateStrategy: .segmentRemoval,
                                                             largeSegments: ["not_in_segments"], data: nil,
                                                             hash: nil, seed: nil, timeMillis: 0)
        segmentsNonRemovalTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func segmentsNonRemovalTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType) {

        helperFor(resource: resource).process(info)
        ThreadUtils.delay(seconds: 2)

        XCTAssertEqual(3, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertFalse(updateNotified(resource, forKey: userKey))
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testSegmentsKeyListRemove() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]

        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s3", data: "some data")
        segmentsKeyListRemoveTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testLargeSegmentsKeyListRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .gzip,
                                                             updateStrategy: .keyList,
                                                             largeSegments: ["s3"], data: "some data",
                                                             hash: nil, seed: nil, timeMillis: 0)

        segmentsKeyListRemoveTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func segmentsKeyListRemoveTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType) {

        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [4, 5], removed: [keyHash, 3])

        let exp = expForResource(resource)

        helperFor(resource: resource).process(info)

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2"], mySegmentsStorage.segments[userKey]?.sorted())
        XCTAssertEqual(2, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(updateNotified(resource, forKey: userKey))
        XCTAssertTrue(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testSegmentsKeyListAdd() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]

        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")
        segmentsUpdateKeyListAddTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testLargeSegmentsKeyListAdd() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .gzip,
                                                             updateStrategy: .keyList,
                                                             largeSegments: ["s5"], data: "some data",
                                                             hash: nil, seed: nil, timeMillis: 0)

        segmentsUpdateKeyListAddTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func segmentsUpdateKeyListAddTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType) {

        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [keyHash, 5], removed: [1, 3])

        let exp = expForResource(resource)

        helperFor(resource: resource).process(info)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(["s1", "s2", "s3", "s5"], mySegmentsStorage.segments[userKey]?.sorted())
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(updateNotified(resource, forKey: userKey))
        XCTAssertTrue(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testSegmentsKeyListNoAction() {
        let notification = MySegmentsUpdateV2Notification(changeNumber: nil,
                                                          compressionType: .gzip,
                                                          updateStrategy: .keyList,
                                                          segmentName: "s5", data: "some data")

        segmentsUpdateKeyListNoActionTest(info: SegmentsProcessInfo(notification), resource: .mySegments)
    }

    func testLargeSegmentsKeyListNoAction() {
        let notification = MyLargeSegmentsUpdateNotification(changeNumber: nil,
                                                             compressionType: .gzip,
                                                             updateStrategy: .keyList,
                                                             largeSegments: ["s5"], data: "some data",
                                                             hash: nil, seed: nil, timeMillis: 0)

        segmentsUpdateKeyListNoActionTest(info: SegmentsProcessInfo(notification), resource: .myLargeSegments)
    }

    func segmentsUpdateKeyListNoActionTest(info: SegmentsProcessInfo, resource: TelemetryUpdatesFromSseType) {
        let bytes = Array(userKey.utf8)
        let keyHash = Murmur64x128.hash(data: bytes, offset: 0, length: UInt32(bytes.count), seed: 0)[0]
        mySegmentsPayloadDecoder.hashedKey = keyHash
        mySegmentsPayloadDecoder.parsedKeyList = KeyList(added: [6, 5], removed: [1, 3])

        helperFor(resource: resource).process(info)
        ThreadUtils.delay(seconds: 1)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(synchronizer.notifySegmentsUpdatedForKeyCalled[userKey] ?? false)
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
    }

    private func helperFor(resource: TelemetryUpdatesFromSseType) -> SegmentsUpdateWorkerHelper {
        let syncWrapper: SegmentsSynchronizerWrapper =
        (resource == .mySegments ? MySegmentsSynchronizerWrapper(synchronizer: synchronizer)
                           : MyLargeSegmentsSynchronizerWrapper(synchronizer: synchronizer))
        return DefaultSegmentsUpdateWorkerHelper(synchronizer: syncWrapper,
                                                 mySegmentsStorage: mySegmentsStorage,
                                                 payloadDecoder: mySegmentsPayloadDecoder,
                                                 telemetryProducer: telemetryProducer,
                                                 resource: resource)

    }

    private func expForResource(_ resource: TelemetryUpdatesFromSseType) -> XCTestExpectation {
        let exp = XCTestExpectation(description: "exp")
        if resource == .mySegments {
            synchronizer.notifyMySegmentsUpdatedExp[userKey] = exp
        } else {
            synchronizer.notifyMyLargeSegmentsUpdatedExp[userKey] = exp
        }
        return exp
    }

    private func expFetchResource(_ resource: TelemetryUpdatesFromSseType) -> XCTestExpectation {
        let exp = XCTestExpectation(description: "exp")
        if resource == .mySegments {
            synchronizer.forceMySegmentsSyncExp[userKey] = exp
        } else {
            synchronizer.forceMyLargeSegmentsSyncExp[userKey] = exp
        }
        return exp
    }

    private func updateNotified(_ resource: TelemetryUpdatesFromSseType, forKey userKey: String) -> Bool {
        if resource == .mySegments {
            return synchronizer.notifySegmentsUpdatedForKeyCalled[userKey] ?? false
        }
        return synchronizer.notifyLargeSegmentsUpdatedForKeyCalled[userKey] ?? false
    }

    private func forceSyncCalled(_ resource: TelemetryUpdatesFromSseType, forKey userKey: String) -> Bool {
        if resource == .mySegments {
            return synchronizer.forceMySegmentsSyncForKeyCalled[userKey] ?? false
        }
        return synchronizer.forceMyLargeSegmentsSyncForKeyCalled[userKey] ?? false
    }
}

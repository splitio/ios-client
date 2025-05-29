//
//  SegmentsUpdateWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SegmentsUpdateWorkerTests: XCTestCase {
    var synchronizer: SynchronizerStub!
    var mySegmentsStorage: MySegmentsStorageStub!
    var mySegmentsChangesChecker: MySegmentsChangesCheckerMock!
    var mySegmentsPayloadDecoder: SegmentsPayloadDecoderMock!
    let userKey = IntegrationHelper.dummyUserKey
    var userKeyHash: String = ""
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        userKeyHash = DefaultMySegmentsPayloadDecoder().hash(userKey: userKey)
        synchronizer = SynchronizerStub()
        mySegmentsChangesChecker = MySegmentsChangesCheckerMock()
        mySegmentsPayloadDecoder = SegmentsPayloadDecoderMock()
        telemetryProducer = TelemetryStorageStub()
        mySegmentsStorage = MySegmentsStorageStub()
        mySegmentsStorage.segments[userKey] = []
    }

    func testUnbounded() throws {
        let notification = newNotification(type: .mySegmentsUpdate, strategy: .unboundedFetchRequest)
        unboundedTest(info: notification, resource: .mySegments)
    }

    func testUnboundedLarge() throws {
        let notification = newNotification(type: .myLargeSegmentsUpdate, cn: 100, strategy: .unboundedFetchRequest)
        unboundedTest(info: notification, resource: .myLargeSegments)
    }

    func unboundedTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType, delay: Int64 = 0) {
        let exp = expFetchResource(resource)

        helperFor(resource: resource).process(info)
        wait(for: [exp], timeout: 3)

        XCTAssertEqual(0, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertTrue(synchronizer.forceMySegmentsSyncForKeyCalled[userKey] ?? false)
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testMySegmentsRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .none,
            strategy: .segmentRemoval,
            segments: ["s3"])
        segmentsRemovalTest(info: notification, resource: .mySegments)
    }

    func testMyLargeSegmentsRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .none,
            strategy: .segmentRemoval,
            segments: ["s3"],
            timeMillis: 500)

        segmentsRemovalTest(info: notification, resource: .myLargeSegments)
    }

    func segmentsRemovalTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType) {
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
        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .none,
            strategy: .segmentRemoval,
            segments: ["not_in_segments"])
        segmentsNonRemovalTest(info: notification, resource: .mySegments)
    }

    func testMyLargeSegmentsNonRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = newNotification(
            type: .myLargeSegmentsUpdate,
            compressionType: .none,
            strategy: .segmentRemoval,
            segments: ["not_in_segments"])
        segmentsNonRemovalTest(info: notification, resource: .myLargeSegments)
    }

    func segmentsNonRemovalTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType) {
        helperFor(resource: resource).process(info)
        ThreadUtils.delay(seconds: 2)

        XCTAssertEqual(3, mySegmentsStorage.segments[userKey]?.count ?? -1)
        XCTAssertFalse(mySegmentsStorage.clearForKeyCalled[userKey] ?? false)
        XCTAssertFalse(updateNotified(resource, forKey: userKey))
        XCTAssertFalse(telemetryProducer.recordUpdatesFromSseCalled)
    }

    func testSegmentsKeyListRemove() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]

        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s3"],
            data: "some data")
        segmentsKeyListRemoveTest(info: notification, resource: .mySegments)
    }

    func testLargeSegmentsKeyListRemoval() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = newNotification(
            type: .myLargeSegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s3"],
            data: "some data",
            timeMillis: 0)

        segmentsKeyListRemoveTest(info: notification, resource: .myLargeSegments)
    }

    func segmentsKeyListRemoveTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType) {
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

        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s5"],
            data: "some data")
        segmentsUpdateKeyListAddTest(info: notification, resource: .mySegments)
    }

    func testLargeSegmentsKeyListAdd() {
        mySegmentsStorage.segments[userKey] = ["s1", "s2", "s3"]
        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s5"],
            data: "some data")
        segmentsUpdateKeyListAddTest(info: notification, resource: .myLargeSegments)
    }

    func segmentsUpdateKeyListAddTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType) {
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
        let notification = newNotification(
            type: .mySegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s5"],
            data: "some data")

        segmentsUpdateKeyListNoActionTest(info: notification, resource: .mySegments)
    }

    func testLargeSegmentsKeyListNoAction() {
        let notification = newNotification(
            type: .myLargeSegmentsUpdate,
            compressionType: .gzip,
            strategy: .keyList,
            segments: ["s5"],
            data: "some data")
        segmentsUpdateKeyListNoActionTest(info: notification, resource: .myLargeSegments)
    }

    func segmentsUpdateKeyListNoActionTest(info: MembershipsUpdateNotification, resource: TelemetryUpdatesFromSseType) {
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

    private func helperFor(resource: TelemetryUpdatesFromSseType) -> SegmentsUpdateWorker {
        let syncWrapper: SegmentsSynchronizerWrapper =
            (
                resource == .mySegments ? MySegmentsSynchronizerWrapper(synchronizer: synchronizer)
                    : MyLargeSegmentsSynchronizerWrapper(synchronizer: synchronizer))
        return SegmentsUpdateWorker(
            synchronizer: syncWrapper,
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
        synchronizer.forceMySegmentsSyncExp[userKey] = exp
        return exp
    }

    private func updateNotified(_ resource: TelemetryUpdatesFromSseType, forKey userKey: String) -> Bool {
        if resource == .mySegments {
            return synchronizer.notifySegmentsUpdatedForKeyCalled[userKey] ?? false
        }
        return synchronizer.notifyLargeSegmentsUpdatedForKeyCalled[userKey] ?? false
    }

    private func newNotification(
        type: NotificationType,
        cn: Int64? = nil,
        compressionType: CompressionType = .gzip,
        strategy: MySegmentUpdateStrategy,
        segments: [String] = [],
        data: String? = nil,
        hash: FetchDelayAlgo? = nil,
        seed: Int? = nil,
        timeMillis: Int64? = nil) -> MembershipsUpdateNotification {
        var notification = MembershipsUpdateNotification(
            changeNumber: cn,
            compressionType: compressionType,
            updateStrategy: strategy,
            segments: segments,
            data: data,
            hash: hash,
            seed: seed,
            timeMillis: timeMillis)
        notification.segmentType = type
        return notification
    }
}

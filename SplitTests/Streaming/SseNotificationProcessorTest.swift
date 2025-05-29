//
//  NotificationProcessorTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SseNotificationProcessorTest: XCTestCase {
    var sseNotificationParser: SseNotificationParserStub!
    var splitsUpdateWorker: SplitsUpdateWorkerMock!
    var mySegmentsUpdateWorker: SegmentsUpdateWorkerMock!
    var myLargeSegmentsUpdateWorker: SegmentsUpdateWorkerMock!
    var splitKillWorker: SplitKillWorkerMock!
    let userKey = IntegrationHelper.dummyUserKey
    var payloadDecoderMock: SegmentsPayloadDecoder!

    var notificationProcessor: SseNotificationProcessor!

    override func setUp() {
        let synchronizer = SynchronizerStub()
        let splitsStorage = SplitsStorageStub()
        let ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        payloadDecoderMock = SegmentsPayloadDecoderMock()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: [],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 100))
        let mySegmentsStorage = MySegmentsStorageStub()

        sseNotificationParser = SseNotificationParserStub()
        splitsUpdateWorker = SplitsUpdateWorkerMock(
            synchronizer: synchronizer,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            splitChangeProcessor: SplitChangeProcessorStub(),
            ruleBasedSegmentsChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            featureFlagsPayloadDecoder: FeatureFlagsPayloadDecoderMock(
                type: Split
                    .self),
            ruleBasedSegmentsPayloadDecoder: RuleBasedSegmentsPayloadDecoderMock(
                type: RuleBasedSegment
                    .self),
            telemetryProducer: TelemetryStorageStub())

        mySegmentsUpdateWorker = SegmentsUpdateWorkerMock(
            synchronizer: MySegmentsSynchronizerWrapper(synchronizer: synchronizer),
            mySegmentsStorage: mySegmentsStorage,
            payloadDecoder: payloadDecoderMock,
            telemetryProducer: nil,
            resource: .mySegments)

        myLargeSegmentsUpdateWorker = SegmentsUpdateWorkerMock(
            synchronizer: MyLargeSegmentsSynchronizerWrapper(synchronizer: synchronizer),
            mySegmentsStorage: mySegmentsStorage,
            payloadDecoder: payloadDecoderMock,
            telemetryProducer: nil,
            resource: .mySegments)

        splitKillWorker = SplitKillWorkerMock(synchronizer: synchronizer, splitsStorage: splitsStorage)

        notificationProcessor = DefaultSseNotificationProcessor(
            notificationParser: sseNotificationParser,
            splitsUpdateWorker: splitsUpdateWorker,
            splitKillWorker: splitKillWorker,
            mySegmentsUpdateWorker: mySegmentsUpdateWorker,
            myLargeSegmentsUpdateWorker: myLargeSegmentsUpdateWorker)
    }

    func testProcessSplitUpdate() {
        sseNotificationParser.splitsUpdateNotification = TargetingRuleUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(
            type: .splitUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitUpdateNullJson() {
        sseNotificationParser.splitsUpdateNotification = TargetingRuleUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(
            type: .splitUpdate,
            channel: nil,
            jsonData: nil,
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitUpdateException() {
        splitsUpdateWorker.throwException = true
        sseNotificationParser.splitsUpdateNotification = TargetingRuleUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(
            type: .splitUpdate,
            channel: nil,
            jsonData: nil,
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitKill() {
        sseNotificationParser.splitKillNotification = SplitKillNotification(
            changeNumber: -1,
            splitName: "split1",
            defaultTreatment: "off")
        let notification = IncomingNotification(
            type: .splitKill,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(splitKillWorker.processCalled)
    }

    func testProcessSplitKillNullJson() {
        sseNotificationParser.splitKillNotification = SplitKillNotification(
            changeNumber: -1,
            splitName: "split1",
            defaultTreatment: "off")
        let notification = IncomingNotification(
            type: .splitKill,
            channel: nil,
            jsonData: nil,
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitKillWorker.processCalled)
    }

    func testProcessSplitKillException() {
        splitKillWorker.throwException = true
        sseNotificationParser.splitKillNotification = SplitKillNotification(
            changeNumber: -1,
            splitName: "split1",
            defaultTreatment: "off")
        let notification = IncomingNotification(
            type: .splitKill,
            channel: nil,
            jsonData: nil,
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitKillWorker.processCalled)
    }

    func testProcessMySegmentsUpdateUnboundedFetchRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMsUpdateNotification(
            changeNumber: -1,
            compressionType: .none,
            updateStrategy: .unboundedFetchRequest,
            segmentName: "",
            data: nil)
        let notification = IncomingNotification(
            type: .mySegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMySegmentsUpdateKeyListRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMsUpdateNotification(
            changeNumber: -1,
            compressionType: .gzip,
            updateStrategy: .keyList,
            segmentName: "pepe",
            data: nil)
        let notification = IncomingNotification(
            type: .mySegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMySegmentsUpdateBoundedRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMsUpdateNotification(
            changeNumber: -1,
            compressionType: .gzip,
            updateStrategy: .boundedFetchRequest,
            segmentName: "",
            data: nil)
        let notification = IncomingNotification(
            type: .mySegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMyLargeSegmentsUpdateUnboundedFetchRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMlsUpdateNotification(
            changeNumber: -1,
            compressionType: .none,
            updateStrategy: .unboundedFetchRequest,
            largeSegments: nil,
            data: nil,
            hash: nil,
            seed: 0,
            timeMillis: 100)
        let notification = IncomingNotification(
            type: .myLargeSegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(myLargeSegmentsUpdateWorker.processCalled)
    }

    func testProcessMyLargeSegmentsUpdateKeyListRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMlsUpdateNotification(
            changeNumber: -1,
            compressionType: .gzip,
            updateStrategy: .keyList,
            largeSegments: ["pepe"],
            data: nil,
            hash: nil,
            seed: 0,
            timeMillis: 100)
        let notification = IncomingNotification(
            type: .myLargeSegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(myLargeSegmentsUpdateWorker.processCalled)
    }

    func testProcessMyLargeSegmentsUpdateBoundedRequest() {
        sseNotificationParser.membershipsUpdateNotification = createMlsUpdateNotification(
            changeNumber: -1,
            compressionType: .gzip,
            updateStrategy: .boundedFetchRequest,
            largeSegments: nil,
            data: nil,
            hash: nil,
            seed: 0,
            timeMillis: 100)

        let notification = IncomingNotification(
            type: .myLargeSegmentsUpdate,
            channel: nil,
            jsonData: "",
            timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(myLargeSegmentsUpdateWorker.processCalled)
    }

    func createMsUpdateNotification(
        changeNumber: Int64?,
        compressionType: CompressionType = .gzip,
        updateStrategy: MySegmentUpdateStrategy,
        segmentName: String,
        data: String?) -> MembershipsUpdateNotification {
        var notification = MembershipsUpdateNotification(
            changeNumber: changeNumber,
            compressionType: compressionType,
            updateStrategy: updateStrategy,
            segments: [segmentName],
            data: data,
            hash: nil,
            seed: nil,
            timeMillis: nil)
        notification.segmentType = .myLargeSegmentsUpdate
        return notification
    }

    func createMlsUpdateNotification(
        changeNumber: Int64?,
        compressionType: CompressionType = .gzip,
        updateStrategy: MySegmentUpdateStrategy,
        largeSegments: [String]?,
        data: String? = nil,
        hash: FetchDelayAlgo? = nil,
        seed: Int? = 0,
        timeMillis: Int64? = nil) -> MembershipsUpdateNotification {
        var notification = MembershipsUpdateNotification(
            changeNumber: changeNumber,
            compressionType: compressionType,
            updateStrategy: updateStrategy,
            segments: largeSegments,
            data: data,
            hash: hash,
            seed: seed,
            timeMillis: timeMillis)
        notification.segmentType = .myLargeSegmentsUpdate
        return notification
    }
}

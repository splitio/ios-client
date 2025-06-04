//
//  SseHandlerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SseHandlerTest: XCTestCase {

    var notificationProcessor: SseNotificationProcessorStub!
    var notificationParser: SseNotificationParserStub!
    var notificationManagerKeeper: NotificationManagerKeeperStub!
    var broadcasterChannel: SyncEventBroadcasterStub!

    var sseHandler: SseHandler!

    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        telemetryProducer = TelemetryStorageStub()
        notificationParser = SseNotificationParserStub()
        notificationProcessor = SseNotificationProcessorStub()
        notificationManagerKeeper = NotificationManagerKeeperStub()
        broadcasterChannel = SyncEventBroadcasterStub()
        sseHandler = DefaultSseHandler(notificationProcessor: notificationProcessor,
                                       notificationParser: notificationParser,
                                       notificationManagerKeeper: notificationManagerKeeper,
                                       broadcasterChannel: broadcasterChannel,
                                       telemetryProducer: telemetryProducer
        )
    }

    func testIncomingSplitUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitUpdate, jsonData: "dummy")
        notificationParser.splitsUpdateNotification = TargetingRuleUpdateNotification(changeNumber: -1 ,
                                                                               previousChangeNumber: nil,
                                                                               definition: nil,
                                                                               compressionType: nil)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingSplitKill() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitKill, jsonData: "dummy")
        notificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1, splitName: "split1", defaultTreatment: "off")
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingMySegmentsUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .mySegmentsUpdate, jsonData: "dummy")
        notificationParser.membershipsUpdateNotification = MembershipsUpdateNotification(changeNumber: -1,
                                                                                         compressionType: .gzip,
                                                                                         updateStrategy: .boundedFetchRequest,
                                                                                         segments: nil,
                                                                                         data: nil,
                                                                                         hash: .none,
                                                                                         seed: 0,
                                                                                         timeMillis: 60)

        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testNoProcessIncomingWhenStreamingInactive() {
        notificationParser.incomingNotification = IncomingNotification(type: .mySegmentsUpdate, jsonData: "dummy")
        notificationParser.membershipsUpdateNotification = MembershipsUpdateNotification(changeNumber: -1,
                                                                                         compressionType: .gzip,
                                                                                         updateStrategy: .boundedFetchRequest,
                                                                                         segments: nil,
                                                                                         data: nil,
                                                                                         hash: .none,
                                                                                         seed: 0,
                                                                                         timeMillis: 60)
        notificationManagerKeeper.isStreamingActive = false

        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationProcessor.processCalled)
    }


    func testIncomingOccupancy() {
        notificationParser.incomingNotification = IncomingNotification(type: .occupancy, jsonData: "dummy")
        notificationParser.occupancyNotification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertTrue(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)

    }

    func testIncomingControlStreaming() {
        notificationParser.incomingNotification = IncomingNotification(type: .control, jsonData: "dummy", timestamp: 100)
        notificationParser.controlNotification = ControlNotification(type: .control, controlType: .streamingResumed)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertTrue(notificationManagerKeeper.handleIncomingControlCalled)
    }

    func testIncomingLowRetryableSseError() {
        notificationParser.isError = true
        incomingRetryableSseErrorTest(code: 40140)
    }

    func testIncomingHightRetryableSseError() {
        notificationParser.isError = true
        incomingRetryableSseErrorTest(code: 40149)
    }

    func incomingRetryableSseErrorTest(code: Int) {
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: code, statusCode: code)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertEqual(SyncStatusEvent.pushRetryableError, broadcasterChannel.lastPushedEvent)

        XCTAssertNotNil(streamEvents[.ablyError])
    }

    func testIncomingLowNonRetryableSseError() {
        notificationParser.isError = true
        incomingNonRetryableSseErrorTest(code: 40000)
    }

    func testIncomingHightNonRetryableSseError() {
        notificationParser.isError = true
        incomingNonRetryableSseErrorTest(code: 49999)
    }

    func incomingNonRetryableSseErrorTest(code: Int) {
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: code, statusCode: code)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertEqual(SyncStatusEvent.pushNonRetryableError, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingIgnorableSseErrorTest() {
        notificationParser.isError = true
        notificationParser.incomingNotification = IncomingNotification(type: .sseError, jsonData: "dummy")
        notificationParser.sseErrorNotification = StreamingError(message: "", code: 50000, statusCode: 50000)
        sseHandler.handleIncomingMessage(message: ["data": "{pepe}"])

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
        XCTAssertNil(broadcasterChannel.lastPushedEvent)

        XCTAssertNotNil(streamEvents[.ablyError])
    }
}

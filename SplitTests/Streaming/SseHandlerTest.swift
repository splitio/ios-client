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

    var sseHandler: SseHandler!

    override func setUp() {
        notificationParser = SseNotificationParserStub()
        notificationProcessor = SseNotificationProcessorStub()
        notificationManagerKeeper = NotificationManagerKeeperStub()
        sseHandler = DefaultSseHandler(notificationProcessor: notificationProcessor,
                                       notificationParser: notificationParser,
                                       notificationManagerKeeper: notificationManagerKeeper)
    }

    func testIncomingSplitUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitUpdate, jsonData: "dummy")
        notificationParser.splitsUpdateNotification = SplitsUpdateNotification(changeNumber: -1)
        sseHandler.handleIncommingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingSplitKill() {
        notificationParser.incomingNotification = IncomingNotification(type: .splitKill, jsonData: "dummy")
        notificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1, splitName: "split1", defaultTreatment: "off")
        sseHandler.handleIncommingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingMySegmentsUpdate() {
        notificationParser.incomingNotification = IncomingNotification(type: .mySegmentsUpdate, jsonData: "dummy")
        notificationParser.mySegmentsUpdateNotification = MySegmentsUpdateNotification(changeNumber: -1, includesPayload: true, segmentList: [])
        sseHandler.handleIncommingMessage(message: ["data": "{pepe}"])

        XCTAssertFalse(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertTrue(notificationProcessor.processCalled)
    }

    func testIncomingOccupancy() {
        notificationParser.incomingNotification = IncomingNotification(type: .occupancy, jsonData: "dummy")
        notificationParser.occupancyNotification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        sseHandler.handleIncommingMessage(message: ["data": "{pepe}"])

        XCTAssertTrue(notificationManagerKeeper.handleIncomingPresenceEventCalled)
        XCTAssertFalse(notificationProcessor.processCalled)
    }

    override func tearDown() {
    }
}

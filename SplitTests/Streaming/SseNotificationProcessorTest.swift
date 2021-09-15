//
//  NotificationProcessorTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SseNotificationProcessorTest: XCTestCase {

    var sseNotificationParser: SseNotificationParserStub!
    var splitsUpdateWorker: SplitsUpdateWorkerMock!
    var mySegmentsUpdateWorker: MySegmentsUpdateWorkerMock!
    var mySegmentsUpdateV2Worker: MySegmentsUpdateV2WorkerMock!
    var splitKillWorker: SplitKillWorkerMock!

    var notificationProcessor: SseNotificationProcessor!

    override func setUp() {
        let synchronizer = SynchronizerStub()
        let splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        let mySegmentsStorage = MySegmentsStorageStub()

        sseNotificationParser = SseNotificationParserStub()
        splitsUpdateWorker = SplitsUpdateWorkerMock(synchronizer: synchronizer)
        mySegmentsUpdateWorker =  MySegmentsUpdateWorkerMock(synchronizer: synchronizer, mySegmentsStorage: mySegmentsStorage)
        mySegmentsUpdateV2Worker =  MySegmentsUpdateV2WorkerMock(synchronizer: synchronizer, mySegmentsStorage: mySegmentsStorage)
        splitKillWorker = SplitKillWorkerMock(synchronizer: synchronizer, splitsStorage: splitsStorage)

        notificationProcessor = DefaultSseNotificationProcessor(notificationParser: sseNotificationParser,
                                                                splitsUpdateWorker: splitsUpdateWorker,
                                                                splitKillWorker: splitKillWorker,
                                                                mySegmentsUpdateWorker: mySegmentsUpdateWorker,
                                                                mySegmentsUpdateV2Worker: mySegmentsUpdateV2Worker)
    }

    func testProcessSplitUpdate() {
        sseNotificationParser.splitsUpdateNotification = SplitsUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(type: .splitUpdate,
                                                channel: nil,
                                                jsonData: "",
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitUpdateNullJson() {
        sseNotificationParser.splitsUpdateNotification = SplitsUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(type: .splitUpdate,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitUpdateException() {
        splitsUpdateWorker.throwException = true
        sseNotificationParser.splitsUpdateNotification = SplitsUpdateNotification(changeNumber: -1)
        let notification = IncomingNotification(type: .splitUpdate,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitsUpdateWorker.processCalled)
    }

    func testProcessSplitKill() {
        sseNotificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1,
                                                                            splitName: "split1",
                                                                            defaultTreatment: "off")
        let notification = IncomingNotification(type: .splitKill,
                                                channel: nil,
                                                jsonData: "",
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(splitKillWorker.processCalled)
    }

    func testProcessSplitKillNullJson() {
        sseNotificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1,
                                                                            splitName: "split1",
                                                                            defaultTreatment: "off")
        let notification = IncomingNotification(type: .splitKill,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitKillWorker.processCalled)
    }

    func testProcessSplitKillException() {
        splitKillWorker.throwException = true
        sseNotificationParser.splitKillNotification = SplitKillNotification(changeNumber: -1,
                                                                            splitName: "split1",
                                                                            defaultTreatment: "off")
        let notification = IncomingNotification(type: .splitKill,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(splitKillWorker.processCalled)
    }

    func testProcessMySegmentsUpdate() {
        sseNotificationParser.mySegmentsUpdateNotification = MySegmentsUpdateNotification(changeNumber: -1,
                                                                                          includesPayload: false,
                                                                                          segmentList: [String]())
        let notification = IncomingNotification(type: .mySegmentsUpdate,
                                                channel: nil,
                                                jsonData: "",
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMySegmentsUpdateNullJson() {
        sseNotificationParser.mySegmentsUpdateNotification = MySegmentsUpdateNotification(changeNumber: -1,
                                                                                          includesPayload: false,
                                                                                          segmentList: [String]())
        let notification = IncomingNotification(type: .mySegmentsUpdate,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMySegmentsUpdateException() {

        mySegmentsUpdateWorker.throwException = true
        sseNotificationParser.mySegmentsUpdateNotification = MySegmentsUpdateNotification(changeNumber: -1,
                                                                                          includesPayload: false,
                                                                                          segmentList: [String]())
        let notification = IncomingNotification(type: .mySegmentsUpdate,
                                                channel: nil,
                                                jsonData: nil,
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertFalse(mySegmentsUpdateWorker.processCalled)
    }

    func testProcessMySegmentsUpdateV2UnboundedFetchRequest() {
        sseNotificationParser.mySegmentsUpdateV2Notification = MySegmentsUpdateV2Notification(changeNumber: -1,
                                                                                              compressionType: .none,
                                                                                              updateStrategy: .unboundedFetchRequest,
                                                                                              segmentName: nil,
                                                                                              data: nil)
        let notification = IncomingNotification(type: .mySegmentsUpdateV2,
                                                channel: nil,
                                                jsonData: "",
                                                timestamp: 1000)
        notificationProcessor.process(notification)

        XCTAssertTrue(mySegmentsUpdateV2Worker.processCalled)
    }

    override func tearDown() {

    }
}

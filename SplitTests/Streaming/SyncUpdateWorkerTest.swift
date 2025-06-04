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
    var mySegmentsUpdateWorker: SegmentsUpdateWorker!
    var myLargeSegmentsUpdateWorker: SegmentsUpdateWorker!
    var splitKillWorker: SplitKillWorker!

    var synchronizer: SynchronizerStub!
    var splitsStorage: SplitsStorageStub!
    var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    let userKey = IntegrationHelper.dummyUserKey
    var userKeyHash: String = ""
    var telemetryProducer: TelemetryStorageStub!
    var splitChangeProcessor: SplitChangeProcessorStub!
    var ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessorStub!

    override func setUp() {
        userKeyHash = DefaultMySegmentsPayloadDecoder().hash(userKey: userKey)
        synchronizer = SynchronizerStub()
        splitsStorage = SplitsStorageStub()
        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        ruleBasedSegmentChangeProcessor = RuleBasedSegmentChangeProcessorStub()
        telemetryProducer = TelemetryStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "split1")],
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        splitChangeProcessor = SplitChangeProcessorStub()
        splitsUpdateWorker = SplitsUpdateWorker(synchronizer: synchronizer,
                                                splitsStorage: splitsStorage,
                                                ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                splitChangeProcessor: splitChangeProcessor,
                                                ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                featureFlagsPayloadDecoder: FeatureFlagsPayloadDecoderMock(type: Split.self),
                                                ruleBasedSegmentsPayloadDecoder: RuleBasedSegmentsPayloadDecoderMock(type: RuleBasedSegment.self),
                                                telemetryProducer: telemetryProducer)

        splitKillWorker = SplitKillWorker(synchronizer: synchronizer, splitsStorage: splitsStorage)
    }

    func testSplitUpdateWorkerNoPayload() throws {
        splitsStorage.changeNumber = 10
        let notification = TargetingRuleUpdateNotification(changeNumber: 100)
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
        var notification = TargetingRuleUpdateNotification(
                                                    changeNumber: 100,
                                                    previousChangeNumber: 10,
                                                    definition: "fake_definition",
                                                    compressionType: .gzip)
        notification.entityType = .splitUpdate

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
        var notification = TargetingRuleUpdateNotification(changeNumber: 100,
                                                    previousChangeNumber: 10,
                                                    definition: "fake_definition",
                                                    compressionType: .gzip)
        notification.entityType = .splitUpdate

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
}

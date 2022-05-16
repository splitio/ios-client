//
//  ImpressionsTrackerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 13-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class ImpressionsTrackerTest: XCTestCase {
    var periodicImpressionsRecorderWorker: PeriodicRecorderWorkerStub!
    var periodicImpressionsCountRecorderWorker: PeriodicRecorderWorkerStub!
    var impressionsRecorderWorker: RecorderWorkerStub!
    var impressionsCountRecorderWorker: RecorderWorkerStub!
    var impressionsTracker: ImpressionsTracker!
    var syncWorkerFactory: SyncWorkerFactoryStub!
    var telemetryProducer: TelemetryStorageStub!
    var impressionsStorage: PersistentImpressionsStorageStub!
    var impressionsCountStorage: PersistentImpressionsCountStorageStub!

    override func setUp() {
        periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
        periodicImpressionsCountRecorderWorker = PeriodicRecorderWorkerStub()
        impressionsRecorderWorker = RecorderWorkerStub()
        impressionsCountRecorderWorker = RecorderWorkerStub()

        syncWorkerFactory = SyncWorkerFactoryStub()

        syncWorkerFactory.periodicImpressionsRecorderWorker = periodicImpressionsRecorderWorker
        syncWorkerFactory.impressionsRecorderWorker = impressionsRecorderWorker
        syncWorkerFactory.periodicImpressionsCountRecorderWorker = periodicImpressionsCountRecorderWorker
        syncWorkerFactory.impressionsCountRecorderWorker = impressionsCountRecorderWorker


        telemetryProducer = TelemetryStorageStub()
        impressionsStorage = PersistentImpressionsStorageStub()
        impressionsCountStorage = PersistentImpressionsCountStorageStub()


        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(),
                                                     splitsStorage: SplitsStorageStub(),
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: impressionsStorage,
                                                     impressionsCountStorage: impressionsCountStorage,
                                                     eventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub())

        let apiFacade = SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        let impressionsRecorderSyncHelper = ImpressionsRecorderSyncHelper(impressionsStorage: impressionsStorage,
                                                                          accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10))
        impressionsTracker = DefaultImpressionsTracker(splitConfig: SplitClientConfig(),
                                                       splitApiFacade: apiFacade,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       impressionsSyncHelper: impressionsRecorderSyncHelper)
    }

    func testImpressionPush() {
        let impression = createImpression()

        for _ in 0..<5 {
            impressionsTracker.push(impression)
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(1, telemetryProducer.impressions[.queued])
        XCTAssertEqual(4, telemetryProducer.impressions[.deduped])
    }

    func testStart() {
        impressionsTracker.start()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.startCalled)
    }

    func testPause() {
        impressionsTracker.start()
        impressionsTracker.pause()

        XCTAssertTrue(periodicImpressionsRecorderWorker.pauseCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.pauseCalled)

    }

    func testResume() {
        impressionsTracker.start()
        impressionsTracker.pause()
        impressionsTracker.resume()

        XCTAssertTrue(periodicImpressionsRecorderWorker.resumeCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.resumeCalled)
    }

    func testStop() {
        impressionsTracker.start()
        impressionsTracker.stop()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
    }

    func testFlush() {
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertTrue(impressionsCountRecorderWorker.flushCalled)
    }

    func testDestroy() {
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.destroyCalled)
    }

    private func createImpression() -> KeyImpression {
        return KeyImpression(featureName: "feature", keyName: "k1",
                             treatment: "t1", label: "the label", time: Date().unixTimestampInMiliseconds(),
                             changeNumber: 1, storageId: "idFeature")

    }

    override func tearDown() {
    }
}


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
    var uniqueKeyTracker: UniqueKeyTrackerStub!

    func testImpressionPushOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        let impression = createImpression()

        for _ in 0..<5 {
            impressionsTracker.push(impression)
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(1, telemetryProducer.impressions[.queued])
        XCTAssertEqual(4, telemetryProducer.impressions[.deduped])
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys.count)
    }

    func testImpressionPushDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        let impression = createImpression()

        for _ in 0..<5 {
            impressionsTracker.push(impression)
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(5, telemetryProducer.impressions[.queued] ?? 0)
        XCTAssertEqual(0, telemetryProducer.impressions[.deduped] ?? 0)
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys.count)
    }

    func testImpressionPushNone() {
        createImpressionsTracker(impressionsMode: .none)

        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f1"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f2"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f3"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f3"))
        impressionsTracker.push(createImpression(keyName: "k2", featureName: "f2"))
        impressionsTracker.push(createImpression(keyName: "k3", featureName: "f3"))

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(0, telemetryProducer.impressions[.queued] ?? 0)
        XCTAssertEqual(0, telemetryProducer.impressions[.deduped] ?? 0)
        XCTAssertEqual(3, uniqueKeyTracker.trackedKeys.count)
        XCTAssertEqual(3, uniqueKeyTracker.trackedKeys["k1"]?.count ?? 0)
    }

    func testStartOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.startCalled)
    }

    func testStartDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.startCalled)
    }

    func testStartNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()

        XCTAssertFalse(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.startCalled)
    }

    func testPause() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.pause()

        XCTAssertTrue(periodicImpressionsRecorderWorker.pauseCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.pauseCalled)

    }

    func testResume() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.pause()
        impressionsTracker.resume()

        XCTAssertTrue(periodicImpressionsRecorderWorker.resumeCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.resumeCalled)
    }

    func testStopOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.stop()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
    }

    func testStopOptimizedDebug() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.stop()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
    }

    func testStopOptimizedNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.stop()

        XCTAssertFalse(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.stopCalled)
    }

    func testFlushOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertTrue(impressionsCountRecorderWorker.flushCalled)
    }

    func testFlushDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertFalse(impressionsCountRecorderWorker.flushCalled)
    }

    func testFlushNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertFalse(impressionsRecorderWorker.flushCalled)
        XCTAssertFalse(impressionsCountRecorderWorker.flushCalled)
    }

    func testDestroyOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.destroyCalled)
    }

    func testDestroyDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.destroyCalled)
    }

    func testDestroyNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertFalse(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.destroyCalled)
    }

    private func createImpression(keyName: String = "k1", featureName: String = "feature") -> KeyImpression {
        return KeyImpression(featureName: featureName, keyName: keyName,
                             treatment: "t1", label: "the label", time: Date().unixTimestampInMiliseconds(),
                             changeNumber: 1, storageId: "idFeature")

    }

    private func createImpressionsTracker(impressionsMode: ImpressionsMode) {

        let config = SplitClientConfig()
        config.setImpressionsMode(impressionsMode)

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

        uniqueKeyTracker = UniqueKeyTrackerStub()


        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(),
                                                     splitsStorage: SplitsStorageStub(),
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: impressionsStorage,
                                                     impressionsCountStorage: impressionsCountStorage,
                                                     eventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub())

        let apiFacade = SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        let impressionsRecorderSyncHelper = ImpressionsRecorderSyncHelper(impressionsStorage: impressionsStorage,
                                                                          accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10))
        impressionsTracker = DefaultImpressionsTracker(splitConfig: config,
                                                       splitApiFacade: apiFacade,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       impressionsSyncHelper: impressionsRecorderSyncHelper,
        uniqueKeyTracker: uniqueKeyTracker)
    }
}


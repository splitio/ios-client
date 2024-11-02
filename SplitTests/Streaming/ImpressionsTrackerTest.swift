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
    var impressionsStorage: ImpressionsStorageStub!
    var persistentImpressionsStorage: PersistentImpressionsStorageStub!
    var impressionsCountStorage: PersistentImpressionsCountStorageStub!
    var uniqueKeysRecorderWorker: RecorderWorkerStub!
    var periodicUniqueKeysRecorderWorker: PeriodicRecorderWorkerStub!
    var flagSetsCache: FlagSetsCacheMock!
    var impressionsObserver: ImpressionsObserver!

    var uniqueKeyTracker: UniqueKeyTrackerStub!

    var notificationHelper: NotificationHelperStub!

    func testImpressionPushOptimized() {
        createImpressionsTracker(impressionsMode: .optimized, realObserver: true)
        let impression = createImpression()

        for _ in 0..<5 {
            impressionsTracker.push(impression)
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(1, telemetryProducer.impressions[.queued])
        XCTAssertEqual(4, telemetryProducer.impressions[.deduped])
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys.count)
        XCTAssertEqual(1, impressionsStorage.impressions.count)
    }

    func testImpressionPushDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        var impression = createImpression()

        for _ in 0..<5 {
            impression.storageId = UUID().uuidString
            impressionsTracker.push(impression)
        }

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(5, telemetryProducer.impressions[.queued] ?? 0)
        XCTAssertEqual(0, telemetryProducer.impressions[.deduped] ?? 0)
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys.count)
        XCTAssertEqual(5, impressionsStorage.impressions.count)
    }

    func testImpressionPushNone() {
        createImpressionsTracker(impressionsMode: .none)

        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f1"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f2"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f3"))
        impressionsTracker.push(createImpression(keyName: "k1", featureName: "f3"))
        impressionsTracker.push(createImpression(keyName: "k2", featureName: "f2"))
        impressionsTracker.push(createImpression(keyName: "k3", featureName: "f3"))

        // Before save an clear
        let trackedKeys = uniqueKeyTracker.trackedKeys

        // Callling pause to save items on storage
        impressionsTracker.pause()

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(0, telemetryProducer.impressions[.queued] ?? 0)
        XCTAssertEqual(0, telemetryProducer.impressions[.deduped] ?? 0)
        XCTAssertEqual(3, trackedKeys.count)
        XCTAssertEqual(3, trackedKeys["k1"]?.count ?? 0)
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys.count)
        XCTAssertEqual(0, uniqueKeyTracker.trackedKeys["k1"]?.count ?? 0)
        XCTAssertEqual(0, impressionsStorage.impressions.count)
        XCTAssertEqual(1, impressionsCountStorage.storedImpressions.values.filter { $0.feature == "f1"}[0].count)
        XCTAssertEqual(2, impressionsCountStorage.storedImpressions.values.filter { $0.feature == "f2"}[0].count)
        XCTAssertEqual(3, impressionsCountStorage.storedImpressions.values.filter { $0.feature == "f3"}[0].count)
    }

    func testStartOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.startCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStartDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.startCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStartNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()

        XCTAssertFalse(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.startCalled)
        XCTAssertTrue(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testPauseOptimized() {
        pauseTest(mode: .optimized)
    }

    func testPauseDebug() {
        pauseTest(mode: .debug)
    }

    func testPauseNone() {
        pauseTest(mode: .none)
    }

    func pauseTest(mode: ImpressionsMode) {
        createImpressionsTracker(impressionsMode: mode)

        let observer = impressionsObserver as! ImpressionsObserverMock

        impressionsTracker.start()
        impressionsTracker.pause()

        if mode != .none {
            XCTAssertTrue(periodicImpressionsRecorderWorker.pauseCalled)
        }

        if mode != .debug {
            XCTAssertTrue(periodicImpressionsCountRecorderWorker.pauseCalled)
            XCTAssertTrue(impressionsCountStorage.pushManyCalled)
        }

        if mode == .none {
            XCTAssertTrue(periodicUniqueKeysRecorderWorker.pauseCalled)
            XCTAssertTrue(uniqueKeyTracker.saveAndClearCalled)
        }

        XCTAssertTrue(observer.saveCalled)
    }

    func testResume() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.pause()
        impressionsTracker.resume()

        XCTAssertTrue(periodicImpressionsRecorderWorker.resumeCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.resumeCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.resumeCalled)
    }

    func testStopOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.stop(.all)

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStopDebug() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.stop(.all)

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStopNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.stop(.all)

        XCTAssertFalse(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
        XCTAssertTrue(periodicUniqueKeysRecorderWorker.stopCalled)
    }

    func testFlushOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertTrue(impressionsCountRecorderWorker.flushCalled)
        XCTAssertFalse(uniqueKeysRecorderWorker.flushCalled)
    }

    func testFlushDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertFalse(impressionsCountRecorderWorker.flushCalled)
        XCTAssertFalse(uniqueKeysRecorderWorker.flushCalled)
    }

    func testFlushNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.flush()

        XCTAssertFalse(impressionsRecorderWorker.flushCalled)
        XCTAssertTrue(impressionsCountRecorderWorker.flushCalled)
        XCTAssertTrue(uniqueKeysRecorderWorker.flushCalled)
    }

    func testDestroyOptimized() {
        createImpressionsTracker(impressionsMode: .optimized)
        let observer = impressionsObserver as! ImpressionsObserverMock
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.destroyCalled)
        XCTAssertTrue(observer.saveCalled)
    }

    func testDestroyDebug() {
        createImpressionsTracker(impressionsMode: .debug)
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicImpressionsCountRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.destroyCalled)
    }

    func testDestroyNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertFalse(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicUniqueKeysRecorderWorker.destroyCalled)
    }

    func testImpressionPushTrackingDisabledDebug() {
        impressionPushTrackingDisabled(mode: .debug)
    }

    func testImpressionPushTrackingDisabledOptimized() {
        impressionPushTrackingDisabled(mode: .optimized)
    }

    func testImpressionPushTrackingDisabledNone() {
        impressionPushTrackingDisabled(mode: .none)
    }

    private func impressionPushTrackingDisabled(mode: ImpressionsMode) {
        createImpressionsTracker(impressionsMode: mode)
        impressionsTracker.enableTracking(false)
        let impression = createImpression(randomId: true)

        for _ in 0..<5 {
            impressionsTracker.push(impression)
        }

        // Before save an clear
        let trackedKeys = uniqueKeyTracker.trackedKeys

        // Callling pause to save items on storage
        impressionsTracker.pause()

        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(0, telemetryProducer.impressions[.queued] ?? 0)
        XCTAssertEqual(0, telemetryProducer.impressions[.deduped] ?? 0)
        XCTAssertEqual(0, trackedKeys.count)
        XCTAssertEqual(0, impressionsCountStorage.storedImpressions.count)
    }

    private func createImpression(keyName: String = "k1", featureName: String = "feature", randomId: Bool = false) -> KeyImpression {
        return KeyImpression(featureName: featureName, keyName: keyName,
                             treatment: "t1", label: "the label", time: Date().unixTimestampInMiliseconds(),
                             changeNumber: 1, storageId: randomId ? UUID().uuidString : "idFeature")

    }

    private func createImpressionsTracker(impressionsMode: ImpressionsMode, 
                                          realObserver: Bool = false) {

        let config = SplitClientConfig()
        config.impressionsMode = impressionsMode.rawValue

        periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
        periodicImpressionsCountRecorderWorker = PeriodicRecorderWorkerStub()
        impressionsRecorderWorker = RecorderWorkerStub()
        impressionsCountRecorderWorker = RecorderWorkerStub()
        uniqueKeysRecorderWorker = RecorderWorkerStub()
        periodicUniqueKeysRecorderWorker = PeriodicRecorderWorkerStub()

        syncWorkerFactory = SyncWorkerFactoryStub()

        syncWorkerFactory.periodicImpressionsRecorderWorker = periodicImpressionsRecorderWorker
        syncWorkerFactory.impressionsRecorderWorker = impressionsRecorderWorker
        syncWorkerFactory.periodicImpressionsCountRecorderWorker = periodicImpressionsCountRecorderWorker
        syncWorkerFactory.impressionsCountRecorderWorker = impressionsCountRecorderWorker
        syncWorkerFactory.uniqueKeysRecorderWorker = uniqueKeysRecorderWorker
        syncWorkerFactory.periodicUniqueKeysRecorderWorker = periodicUniqueKeysRecorderWorker


        telemetryProducer = TelemetryStorageStub()
        impressionsStorage = ImpressionsStorageStub()
        persistentImpressionsStorage = PersistentImpressionsStorageStub()
        impressionsCountStorage = PersistentImpressionsCountStorageStub()

        uniqueKeyTracker = UniqueKeyTrackerStub()
        flagSetsCache = FlagSetsCacheMock()

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     splitsStorage: SplitsStorageStub(),
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: persistentImpressionsStorage,
                                                     impressionsCountStorage: impressionsCountStorage,
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     myLargeSegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub(), 
                                                     flagSetsCache: flagSetsCache,
                                                     persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                                     hashedImpressionsStorage: HashedImpressionsStorageMock())

        let apiFacade = try! SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        let impressionsRecorderSyncHelper = ImpressionsRecorderSyncHelper(impressionsStorage: impressionsStorage,
                                                                          accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10))

        self.impressionsObserver = (realObserver ? DefaultImpressionsObserver(storage: storageContainer.hashedImpressionsStorage) : ImpressionsObserverMock())

        notificationHelper = NotificationHelperStub()
        impressionsTracker = DefaultImpressionsTracker(splitConfig: config,
                                                       splitApiFacade: apiFacade,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       impressionsSyncHelper: impressionsRecorderSyncHelper,
                                                       uniqueKeyTracker: uniqueKeyTracker,
                                                       notificationHelper: notificationHelper,
                                                       impressionsObserver: impressionsObserver)
    }
}


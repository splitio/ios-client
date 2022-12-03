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
    var persistentImpressionsStorage: PersistentImpressionsStorageStub!
    var impressionsCountStorage: PersistentImpressionsCountStorageStub!
    var uniqueKeysRecorderWorker: RecorderWorkerStub!
    var periodicUniqueKeysRecorderWorker: PeriodicRecorderWorkerStub!

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
        XCTAssertEqual(1, persistentImpressionsStorage.storedImpressions.count)
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
        XCTAssertEqual(5, persistentImpressionsStorage.storedImpressions.count)
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
        XCTAssertEqual(0, persistentImpressionsStorage.storedImpressions.count)
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

    func testPause() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.pause()

        XCTAssertTrue(periodicImpressionsRecorderWorker.pauseCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.pauseCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.pauseCalled)

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
        impressionsTracker.stop()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStopDebug() {
        createImpressionsTracker(impressionsMode: .optimized)
        impressionsTracker.start()
        impressionsTracker.stop()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.stopCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.startCalled)
    }

    func testStopNone() {
        createImpressionsTracker(impressionsMode: .none)
        impressionsTracker.start()
        impressionsTracker.stop()

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
        impressionsTracker.start()
        impressionsTracker.destroy()
        XCTAssertTrue(periodicImpressionsRecorderWorker.destroyCalled)
        XCTAssertTrue(periodicImpressionsCountRecorderWorker.destroyCalled)
        XCTAssertFalse(periodicUniqueKeysRecorderWorker.destroyCalled)
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
        impressionsTracker.isTrackingEnabled = false
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

    private func createImpressionsTracker(impressionsMode: ImpressionsMode) {

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
        persistentImpressionsStorage = PersistentImpressionsStorageStub()
        impressionsCountStorage = PersistentImpressionsCountStorageStub()

        uniqueKeyTracker = UniqueKeyTrackerStub()


        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(),
                                                     splitsStorage: SplitsStorageStub(),
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: persistentImpressionsStorage,
                                                     impressionsCountStorage: impressionsCountStorage,
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub())

        let apiFacade = try! SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        let impressionsRecorderSyncHelper = ImpressionsRecorderSyncHelper(impressionsStorage: persistentImpressionsStorage,
                                                                          accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10))
        impressionsTracker = DefaultImpressionsTracker(splitConfig: config,
                                                       splitApiFacade: apiFacade,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       impressionsSyncHelper: impressionsRecorderSyncHelper,
        uniqueKeyTracker: uniqueKeyTracker, notificationHelper: nil)
    }
}


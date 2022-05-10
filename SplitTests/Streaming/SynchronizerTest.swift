//
//  SynchronizerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10-03-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SynchronizerTest: XCTestCase {

    var splitsFetcher: HttpSplitFetcherStub!
    var periodicImpressionsRecorderWorker: PeriodicRecorderWorkerStub!
    var impressionsRecorderWorker: RecorderWorkerStub!
    var periodicEventsRecorderWorker: PeriodicRecorderWorkerStub!
    var eventsRecorderWorker: RecorderWorkerStub!
    var splitsSyncWorker: RetryableSyncWorkerStub!
    var mySegmentsSyncWorker: RetryableSyncWorkerStub!
    var periodicSplitsSyncWorker: PeriodicSyncWorkerStub!
    var persistentSplitsStorage: PersistentSplitsStorageStub!

    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!

    var updateWorkerCatalog = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>()
    var syncWorkerFactory: SyncWorkerFactoryStub!

    var synchronizer: Synchronizer!

    var eventsManager: SplitEventsManagerStub!
    var telemetryProducer: TelemetryStorageStub!
    var byKeyApiFacade: ByKeyFacadeStub!
    var impressionsTracker: ImpressionsTracker!

    let userKey = "CUSTOMER_KEY"

    override func setUp() {
        synchronizer = buildSynchronizer()
    }

    func buildSynchronizer(impressionsAccumulator: RecorderFlushChecker? = nil,
                           eventsAccumulator: RecorderFlushChecker? = nil) -> Synchronizer {

        eventsManager = SplitEventsManagerStub()
        persistentSplitsStorage = PersistentSplitsStorageStub()
        splitsFetcher = HttpSplitFetcherStub()

        splitsSyncWorker = RetryableSyncWorkerStub()
        mySegmentsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
        impressionsRecorderWorker = RecorderWorkerStub()
        periodicEventsRecorderWorker = PeriodicRecorderWorkerStub()
        eventsRecorderWorker = RecorderWorkerStub()

        syncWorkerFactory = SyncWorkerFactoryStub()

        impressionsTracker = ImpressionsTrackStub()

        syncWorkerFactory.splitsSyncWorker = splitsSyncWorker
        syncWorkerFactory.mySegmentsSyncWorker = mySegmentsSyncWorker
        syncWorkerFactory.periodicSplitsSyncWorker = periodicSplitsSyncWorker
        syncWorkerFactory.periodicImpressionsRecorderWorker = periodicImpressionsRecorderWorker
        syncWorkerFactory.impressionsRecorderWorker = impressionsRecorderWorker
        syncWorkerFactory.periodicEventsRecorderWorker = periodicEventsRecorderWorker
        syncWorkerFactory.eventsRecorderWorker = eventsRecorderWorker

        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        telemetryProducer = TelemetryStorageStub()
        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(), splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: persistentSplitsStorage,
                                                     impressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
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

        let config =  SplitClientConfig()
        config.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()

        byKeyApiFacade = ByKeyFacadeStub()


        synchronizer = DefaultSynchronizer(splitConfig: config,
                                           defaultUserKey: userKey,
                                           telemetrySynchronizer: nil,
                                           byKeyFacade: byKeyApiFacade,
                                           splitApiFacade: apiFacade,
                                           splitStorageContainer: storageContainer,
                                           syncWorkerFactory: syncWorkerFactory,
                                           impressionsTracker: impressionsTracker,
                                           eventsSyncHelper:
                                            EventsRecorderSyncHelper(eventsStorage: PersistentEventsStorageStub(),
                                                                     accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10)),
                                           syncTaskByChangeNumberCatalog: updateWorkerCatalog,
                                           splitsFilterQueryString: "",
                                           splitEventsManager: eventsManager)
        return synchronizer
    }

    func testSyncAll() {

        synchronizer.syncAll()

        XCTAssertTrue(splitsSyncWorker.startCalled)
        XCTAssertTrue(byKeyApiFacade.syncAllCalled)
    }

    func testSynchronizeSplits() {

        synchronizer.synchronizeSplits()

        XCTAssertTrue(splitsSyncWorker.startCalled)
    }

    func testLoadAndSyncSplitsClearedOnLoadBecauseNotInFilter() {
        // Existent splits does not belong to split filter on config so they gonna be deleted because filter has changed
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "pepe"))
        persistentSplitsStorage.update(filterQueryString: "?p=1")
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "SPLIT_TO_DELETE"))
        synchronizer.loadAndSynchronizeSplits()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(persistentSplitsStorage.getAllCalled)
        XCTAssertTrue(persistentSplitsStorage.deleteCalled)
        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(0, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadAndSyncSplitsNoClearedOnLoad() {
        // Splits filter doesn't vary so splits don't gonna be removed
        // loaded splits > 0, ready from cache should be fired
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "new_pepe")],
                                                  archivedSplits: [], changeNumber: 100, updateTimestamp: 100))
        persistentSplitsStorage.update(filterQueryString: "")
        synchronizer.loadAndSynchronizeSplits()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(1, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadMySegmentsFromCache() {

        synchronizer.loadMySegmentsFromCache(forKey: userKey)

        ThreadUtils.delay(seconds: 0.2)

        XCTAssertTrue(byKeyApiFacade.loadMySegmentsFromCacheCalled[userKey] ?? false)
    }

    func testSynchronizeMySegments() {

        synchronizer.synchronizeMySegments(forKey: userKey)

        XCTAssertTrue(byKeyApiFacade.syncMySegmentsCalled[userKey] ?? false)
    }

    func testSynchronizeSplitsWithChangeNumber() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        let initialSyncCount = updateWorkerCatalog.count
        sw1.completion?(true)
        let oneCompletedSyncCount = updateWorkerCatalog.count
        sw2.completion?(true)

        XCTAssertEqual(2, initialSyncCount)
        XCTAssertEqual(1, oneCompletedSyncCount)
        XCTAssertEqual(0, updateWorkerCatalog.count)

        XCTAssertFalse(sw1.stopCalled)
        XCTAssertFalse(sw2.stopCalled)
    }

    func testStartPeriodicFetching() {

        synchronizer.startPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.startCalled)
        XCTAssertTrue(byKeyApiFacade.startPeriodicSyncCalled)
    }

    func testStopPeriodicFetching() {

        synchronizer.stopPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.stopPeriodicSyncCalled)
    }

    func testStartPeriodicRecording() {

        synchronizer.startPeriodicRecording()

        XCTAssertTrue(periodicImpressionsRecorderWorker.startCalled)
        XCTAssertTrue(periodicEventsRecorderWorker.startCalled)
    }

    func testStopPeriodicRecording() {

        synchronizer.stopPeriodicRecording()

        XCTAssertTrue(periodicImpressionsRecorderWorker.stopCalled)
        XCTAssertTrue(periodicEventsRecorderWorker.stopCalled)
    }

    func testStartByKey() {
        let key = Key(matchingKey: userKey)
        synchronizer.start(forKey: key)

        XCTAssertTrue(byKeyApiFacade.startSyncForKeyCalled[key] ?? false)
    }

    func testFlush() {

        synchronizer.flush()
        sleep(1)
        XCTAssertTrue(impressionsRecorderWorker.flushCalled)
        XCTAssertTrue(eventsRecorderWorker.flushCalled)
    }

    func testDestroy() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        synchronizer.destroy()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }

    func testImpressionPush() {
        let impression = KeyImpression(featureName: "feature", keyName: "k1",
                                       treatment: "t1", label: nil, time: 1,
                                       changeNumber: 1)

        for _ in 0..<5 {
            synchronizer.pushImpression(impression: impression)
        }


        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(1, telemetryProducer.impressions[.queued])
        XCTAssertEqual(4, telemetryProducer.impressions[.deduped])
    }

    func testEventPush() {


        for i in 0..<5 {
            synchronizer.pushEvent(event: EventDTO(trafficType: "t1", eventType: "e\(i)"))
        }


        ThreadUtils.delay(seconds: 1)
        XCTAssertEqual(5, telemetryProducer.events[.queued])

    }

    override func tearDown() {
    }
}

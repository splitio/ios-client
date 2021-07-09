//
//  SynchronizerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/09/2020.
//  Copyright © 2020 Split. All rights reserved.
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
    var periodicMySegmentsSyncWorker: PeriodicSyncWorkerStub!
    var persistentSplitsStorage: PersistentSplitsStorageStub!

    var splitsStorage: SplitsStorageStub!
    var mySegmentsStorage: MySegmentsStorageStub!

    var updateWorkerCatalog = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>()
    var syncWorkerFactory: SyncWorkerFactoryStub!

    var synchronizer: Synchronizer!

    var eventsManager: SplitEventsManagerStub!

    override func setUp() {

        eventsManager = SplitEventsManagerStub()
        persistentSplitsStorage = PersistentSplitsStorageStub()
        splitsFetcher = HttpSplitFetcherStub()

        splitsSyncWorker = RetryableSyncWorkerStub()
        mySegmentsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        periodicMySegmentsSyncWorker = PeriodicSyncWorkerStub()
        periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
        impressionsRecorderWorker = RecorderWorkerStub()
        periodicEventsRecorderWorker = PeriodicRecorderWorkerStub()
        eventsRecorderWorker = RecorderWorkerStub()

        syncWorkerFactory = SyncWorkerFactoryStub()

        syncWorkerFactory.splitsSyncWorker = splitsSyncWorker
        syncWorkerFactory.mySegmentsSyncWorker = mySegmentsSyncWorker
        syncWorkerFactory.periodicSplitsSyncWorker = periodicSplitsSyncWorker
        syncWorkerFactory.periodicMySegmentsSyncWorker = periodicMySegmentsSyncWorker
        syncWorkerFactory.periodicImpressionsRecorderWorker = periodicImpressionsRecorderWorker
        syncWorkerFactory.impressionsRecorderWorker = impressionsRecorderWorker
        syncWorkerFactory.periodicEventsRecorderWorker = periodicEventsRecorderWorker
        syncWorkerFactory.eventsRecorderWorker = eventsRecorderWorker


        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))
        mySegmentsStorage = MySegmentsStorageStub()

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(), splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: persistentSplitsStorage,
                                                     mySegmentsStorage: mySegmentsStorage, impressionsStorage: PersistentImpressionsStorageStub(), impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: PersistentEventsStorageStub())

        let apiFacade = SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        let config =  SplitClientConfig()
        config.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()
        synchronizer = DefaultSynchronizer(splitConfig: config,
            splitApiFacade: apiFacade,
            splitStorageContainer: storageContainer,
            syncWorkerFactory: syncWorkerFactory,
            impressionsSyncHelper: ImpressionsRecorderSyncHelper(impressionsStorage: PersistentImpressionsStorageStub(),
                                                                 accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10)),
            eventsSyncHelper: EventsRecorderSyncHelper(eventsStorage: PersistentEventsStorageStub(),
                                                                 accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10)),
            syncTaskByChangeNumberCatalog: updateWorkerCatalog, splitsFilterQueryString: "", splitEventsManager: eventsManager)
    }

    func testSyncAll() {

        synchronizer.syncAll()

        XCTAssertTrue(splitsSyncWorker.startCalled)
        XCTAssertTrue(mySegmentsSyncWorker.startCalled)
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

        synchronizer.loadMySegmentsFromCache()

        ThreadUtils.delay(seconds: 0.2)

        XCTAssertTrue(mySegmentsStorage.loadLocalCalled)
        XCTAssertEqual(1, eventsManager.mySegmentsLoadedEventFiredCount)
    }

    func testSynchronizeMySegments() {

        synchronizer.synchronizeMySegments()

        XCTAssertTrue(mySegmentsSyncWorker.startCalled)
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
        XCTAssertTrue(periodicMySegmentsSyncWorker.startCalled)
    }

    func testStopPeriodicFetching() {

        synchronizer.stopPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
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
        XCTAssertTrue(mySegmentsSyncWorker.stopCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }

    override func tearDown() {
    }
}

//
//  FeatureFlagsSynchronizerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation


import XCTest
@testable import Split

class FeatureFlagsSynchronizerTest: XCTestCase {

    var splitsFetcher: HttpSplitFetcherStub!
    var splitsSyncWorker: RetryableSyncWorkerStub!
    var periodicSplitsSyncWorker: PeriodicSyncWorkerStub!
    var persistentSplitsStorage: PersistentSplitsStorageStub!

    var splitsStorage: SplitsStorageStub!

    var updateWorkerCatalog = ConcurrentDictionary<Int64, RetryableSyncWorker>()
    var syncWorkerFactory: SyncWorkerFactoryStub!
    var eventsManager: SplitEventsManagerStub!
    var splitConfig: SplitClientConfig!

    var synchronizer: FeatureFlagsSynchronizer!

    override func setUp() {
        synchronizer = buildSynchronizer()
    }

    func buildSynchronizer(syncEnabled: Bool = true) -> FeatureFlagsSynchronizer {

        eventsManager = SplitEventsManagerStub()
        persistentSplitsStorage = PersistentSplitsStorageStub()
        splitsFetcher = HttpSplitFetcherStub()
        splitsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        syncWorkerFactory = SyncWorkerFactoryStub()
        syncWorkerFactory.splitsSyncWorker = splitsSyncWorker
        syncWorkerFactory.periodicSplitsSyncWorker = periodicSplitsSyncWorker
        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: persistentSplitsStorage,
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: TelemetryStorageStub(),
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub())

        splitConfig =  SplitClientConfig()
        splitConfig.syncEnabled = syncEnabled
        splitConfig.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()

        synchronizer = DefaultFeatureFlagsSynchronizer(splitConfig: splitConfig,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       syncTaskByChangeNumberCatalog: updateWorkerCatalog,
                                                       splitsFilterQueryString: "",
                                                       splitEventsManager: eventsManager)
        return synchronizer
    }

    func testSynchronizeSplits() {

        synchronizer.synchronize()

        XCTAssertTrue(splitsSyncWorker.startCalled)
    }

    func testLoadAndSyncSplitsClearedOnLoadBecauseNotInFilter() {
        // Existent splits does not belong to split filter on config so they gonna be deleted because filter has changed
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "pepe"))
        persistentSplitsStorage.update(filterQueryString: "?p=1")
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "SPLIT_TO_DELETE"))
        synchronizer.loadAndSynchronize()

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
        synchronizer.loadAndSynchronize()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(1, eventsManager.splitsLoadedEventFiredCount)
    }

    func testSynchronizeSplitsWithChangeNumber() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronize(changeNumber: 101)
        synchronizer.synchronize(changeNumber: 102)

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

    func testStartPeriodicSync() {

        synchronizer.startPeriodicSync()

        XCTAssertTrue(periodicSplitsSyncWorker.startCalled)
    }

    func testStartPeriodicFetchingSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.startPeriodicSync()

        XCTAssertFalse(periodicSplitsSyncWorker.startCalled)
    }

    func testUpdateSplitsSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.synchronize(changeNumber: -1)

        XCTAssertFalse(splitsSyncWorker.startCalled)
    }

    func testStopPeriodicSync() {

        synchronizer.stopPeriodicSync()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
    }

    func testStop() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronize(changeNumber: 101)
        synchronizer.synchronize(changeNumber: 102)

        synchronizer.stop()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }
}

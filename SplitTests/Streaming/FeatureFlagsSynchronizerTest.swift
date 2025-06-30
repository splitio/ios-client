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

    var updateWorkerCatalog = ConcurrentDictionary<SplitsUpdateChangeNumber, RetryableSyncWorker>()
    var syncWorkerFactory: SyncWorkerFactoryStub!
    var eventsManager: SplitEventsManagerStub!
    var splitConfig: SplitClientConfig!

    var synchronizer: FeatureFlagsSynchronizer!
    var broadcasterChannel: SyncEventBroadcasterStub!
    var generalInfoStorage: GeneralInfoStorageMock!
    var telemetryStorageStub: TelemetryStorageStub!

    override func setUp() {
        synchronizer = buildSynchronizer()
    }

    func buildSynchronizer(syncEnabled: Bool = true, splitFilters: [SplitFilter]? = nil) -> FeatureFlagsSynchronizer {

        eventsManager = SplitEventsManagerStub()
        persistentSplitsStorage = PersistentSplitsStorageStub()
        splitsFetcher = HttpSplitFetcherStub()
        splitsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        syncWorkerFactory = SyncWorkerFactoryStub()
        syncWorkerFactory.splitsSyncWorker = splitsSyncWorker
        syncWorkerFactory.periodicSplitsSyncWorker = periodicSplitsSyncWorker
        splitsStorage = SplitsStorageStub()
        broadcasterChannel = SyncEventBroadcasterStub()
        generalInfoStorage = GeneralInfoStorageMock()
        telemetryStorageStub = TelemetryStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))
        generalInfoStorage.setFlagSpec(flagsSpec: "1.2")

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: persistentSplitsStorage,
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryStorageStub,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     myLargeSegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub(),
                                                     flagSetsCache: FlagSetsCacheMock(),
                                                     persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                                     hashedImpressionsStorage: HashedImpressionsStorageMock(),
                                                     generalInfoStorage: generalInfoStorage,
                                                     ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                                     persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub())

        splitConfig =  SplitClientConfig()
        splitConfig.syncEnabled = syncEnabled
        if let splitFilters = splitFilters {
            let builder = SyncConfig.builder()
            for splitFilter in splitFilters {
                builder.addSplitFilter(splitFilter)
            }
            splitConfig.sync = builder.build()
        } else {
            splitConfig.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()
        }

        let filterBuilder = FilterBuilder(flagSetsValidator: DefaultFlagSetsValidator(telemetryProducer: telemetryStorageStub))
        let queryString = try? filterBuilder.add(filters: splitFilters ?? []).build()
        synchronizer = DefaultFeatureFlagsSynchronizer(splitConfig: splitConfig,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       broadcasterChannel: broadcasterChannel,
                                                       syncTaskByChangeNumberCatalog: updateWorkerCatalog,
                                                       splitsFilterQueryString: queryString ?? "",
                                                       flagsSpec: "1.2",
                                                       splitEventsManager: eventsManager)
        return synchronizer
    }

    func testSynchronizeSplits() {

        synchronizer.synchronize()

        XCTAssertTrue(splitsSyncWorker.startCalled)
    }

    func testSynchronizeSplitsWithUriTooLong() {

        syncWorkerFactory.splitsSyncWorker.errorToThrowOnStart = .uriTooLong
        synchronizer.synchronize()

        XCTAssertEqual(SyncStatusEvent.uriTooLongOnSync, broadcasterChannel.lastPushedEvent)
    }

    func testLoadSplitsClearedOnLoadBecauseNotInFilter() {
        // Existent splits does not belong to split filter on config so they gonna be deleted because filter has changed
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "pepe"))
        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "?p=1")
        
        persistentSplitsStorage.update(split: TestingHelper.createSplit(name: "SPLIT_TO_DELETE"))
        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(persistentSplitsStorage.getAllCalled)
        XCTAssertTrue(persistentSplitsStorage.deleteCalled)
        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
        XCTAssertEqual(0, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadSplitsNoClearedOnLoad() {
        // Splits filter doesn't vary so splits don't gonna be removed
        // loaded splits > 0, ready from cache should be fired
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [TestingHelper.createSplit(name: "new_pepe")],
                                                  archivedSplits: [], changeNumber: 100, updateTimestamp: 100))
        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "")
        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(splitsStorage.loadLocalCalled)
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
        XCTAssertEqual(1, eventsManager.splitsLoadedEventFiredCount)
    }

    func testLoadSplitWhenQuerystringNamesChanges() {


        let filterByName = SplitFilter.byName(["test1", "test2"])
        let filterByPrefix = SplitFilter.byPrefix(["pre"])
        synchronizer = buildSynchronizer(splitFilters: [filterByName, filterByPrefix])

        let names = ["pre__test1", "pre__test2", "apre__test3", "apre__test4",
                     "test1", "test2", "test3", "test4"]

        for name in names {
            persistentSplitsStorage.update(split: TestingHelper.createSplit(name: name))
        }

        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "?names=pepe")

        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        let deleted = Set(persistentSplitsStorage.deletedSplits)
        XCTAssertTrue(deleted.contains("apre__test3"))
        XCTAssertTrue(deleted.contains("apre__test4"))
        XCTAssertTrue(deleted.contains("test3"))
        XCTAssertTrue(deleted.contains("test4"))
        XCTAssertEqual(4, deleted.count)
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
    }

    func testLoadSplitWhenQuerystringSetsChanges() {


        let filterByName = SplitFilter.bySet(["set3", "set4"])
        let filterByPrefix = SplitFilter.byPrefix(["pre"])
        synchronizer = buildSynchronizer(splitFilters: [filterByName, filterByPrefix])

        let names = ["pre__test1", "pre__test2", "apre__test1", "apre__test2",
                     "test1", "test2"]

        let splitSets: [String: Set<String>] = [
            "tset1": ["set1"],
            "tset2": ["set1", "set2"],
            "tset3": ["set2", "set3", "set4"],
            "tset4": ["set3", "set4"],
            "pre_tset2": ["set3", "set2"],
            "apre_tset3": ["set1", "set5"],
        ]

        for name in names {
            persistentSplitsStorage.update(split: TestingHelper.createSplit(name: name))
        }

        for (name, sets) in splitSets {
            persistentSplitsStorage.update(split: TestingHelper.createSplit(name: name, sets: sets))
        }

        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "?names=pepe")

        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        let deleted = Set(persistentSplitsStorage.deletedSplits)
        XCTAssertTrue(deleted.contains("apre__test1"))
        XCTAssertTrue(deleted.contains("apre__test2"))
        XCTAssertTrue(deleted.contains("pre__test1"))
        XCTAssertTrue(deleted.contains("pre__test2"))
        XCTAssertTrue(deleted.contains("test1"))
        XCTAssertTrue(deleted.contains("test2"))
        XCTAssertTrue(deleted.contains("tset1"))
        XCTAssertTrue(deleted.contains("tset2"))
        XCTAssertTrue(deleted.contains("apre_tset3"))
        XCTAssertEqual(9, deleted.count)
        XCTAssertEqual("&sets=set3,set4", generalInfoStorage.getSplitsFilterQueryString())
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
    }

    func testLoadSplitsWhenFlagsSetsHasChangedClearsAllFeatureFlagsAndUpdatesFlagsSpec() {
        let names = ["test1", "test2", "test3", "test4"]

        for name in names {
            persistentSplitsStorage.update(split: TestingHelper.createSplit(name: name))
        }

        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "")
        generalInfoStorage.setFlagSpec(flagsSpec: "1.1")

        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(persistentSplitsStorage.clearCalled)
        XCTAssertEqual("1.2", generalInfoStorage.getFlagSpec())
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
    }

    func testLoadSplitsWhenFlagsSetsAndFilterHasChangedClearsAllFeatureFlags() {
        let names = ["test1", "test2", "test3", "test4"]

        for name in names {
            persistentSplitsStorage.update(split: TestingHelper.createSplit(name: name))
        }

        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "?names=pepe")
        generalInfoStorage.setFlagSpec(flagsSpec: "1.1")

        synchronizer.load()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue(persistentSplitsStorage.clearCalled)
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.filter { $0 == .splitLoadedFromCache }.count)
    }
    
    func testMetadataOnFeatureFlagsSync() {
        synchronizer.notifyUpdated(flagsList: ["Pepe2"])
        
        XCTAssertEqual(eventsManager.metadata?.type, .FLAGS_UPDATED)
        XCTAssertEqual(eventsManager.metadata?.data, ["Pepe2"])
    }

    func testSynchronizeSplitsWithChangeNumber() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronize(changeNumber: 101, rbsChangeNumber: nil)
        synchronizer.synchronize(changeNumber: 102, rbsChangeNumber: nil)

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
        synchronizer.synchronize(changeNumber: -1, rbsChangeNumber: nil)
        let syncExecCount = broadcasterChannel.pushedEvents.filter { $0 == .syncExecuted }.count

        XCTAssertFalse(splitsSyncWorker.startCalled)
        XCTAssertEqual(0, syncExecCount)
    }

    func testStopPeriodicSync() {

        synchronizer.stopPeriodicSync()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
    }

    func testStop() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronize(changeNumber: 101, rbsChangeNumber: nil)
        synchronizer.synchronize(changeNumber: 102, rbsChangeNumber: nil)

        synchronizer.destroy()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }
}

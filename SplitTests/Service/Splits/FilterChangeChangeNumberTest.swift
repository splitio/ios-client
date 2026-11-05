//
//  FilterChangeChangeNumberTest.swift
//  SplitTests
//
//  When the splits filter changes (and the flags spec does not), the cache must be
//  reset to change number -1 so the next sync is a full fetch (since = -1). Otherwise a
//  broadened or removed filter is never applied: flags excluded by the old filter are
//  not returned by a delta sync (since = cn).
//

import XCTest
@testable import Split

final class FilterChangeChangeNumberTest: XCTestCase {

    private let flagsSpec = "1.2"

    private var database: SplitDatabase!
    private var coreDataHelper: CoreDataHelper!
    private var generalInfoStorage: GeneralInfoStorage!
    private var persistentSplitsStorage: PersistentSplitsStorage!
    private var splitsStorage: DefaultSplitsStorage!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!
    private var telemetryStub: TelemetryStorageStub!

    override func setUp() {
        let dbName = UUID().uuidString
        coreDataHelper = IntegrationCoreDataHelper.get(databaseName: dbName,
                                                       dispatchQueue: DispatchQueue(label: dbName,
                                                                                    target: DispatchQueue.test))
        database = TestingHelper.createTestDatabase(name: dbName, helper: coreDataHelper)
        generalInfoStorage = DefaultGeneralInfoStorage(database: database)
        persistentSplitsStorage = DefaultPersistentSplitsStorage(database: database)
        splitsStorage = DefaultSplitsStorage(
            persistentSplitsStorage: persistentSplitsStorage,
            flagSetsCache: DefaultFlagSetsCache(setsInFilter: nil),
            generalInfoStorage: generalInfoStorage,
            persistenceBreaker: DefaultPersistenceBreaker())
        ruleBasedSegmentsStorage = DefaultRuleBasedSegmentsStorage(
            persistentStorage: DefaultPersistentRuleBasedSegmentsStorage(database: database,
                                                                          generalInfoStorage: generalInfoStorage),
            generalInfoStorage: generalInfoStorage)
        telemetryStub = TelemetryStorageStub()
    }

    /// Stored filter: sets ["a"]. Current filter: sets ["a", "b"] (broadened).
    /// flag_a (set "a") is cached at cn 100; the flags spec is unchanged.
    /// Expected: cn is reset to -1 so the next sync is since = -1.
    func testBroadenedSetFilterResetsSplitsChangeNumber() throws {
        let storedQuery = try queryString(for: [SplitFilter.bySet(["a"])])
        let currentFilters = [SplitFilter.bySet(["a", "b"])]
        let currentQuery = try queryString(for: currentFilters)
        try seedCache(storedQuery: storedQuery)

        let synchronizer = makeSynchronizer(currentFilters: currentFilters, currentQuery: currentQuery)
        synchronizer.load()
        ThreadUtils.delay(seconds: 0.5)
        coreDataHelper.performAndWait {}

        XCTAssertEqual(currentQuery, generalInfoStorage.getSplitsFilterQueryString(),
                       "precondition: filter change was processed")
        XCTAssertEqual(-1, database.generalInfoDao.longValue(info: .splitsChangeNumber),
                       "filter broadened but splits cn was kept, next sync would be a delta")
    }

    /// Stored filter: sets ["a"]. Current config has no filter at all (removed).
    /// Expected: cn is reset to -1 so the next sync is since = -1.
    func testRemovedFilterResetsSplitsChangeNumber() throws {
        let storedQuery = try queryString(for: [SplitFilter.bySet(["a"])])
        let currentQuery = try queryString(for: [])
        try seedCache(storedQuery: storedQuery)

        let synchronizer = makeSynchronizer(currentFilters: [], currentQuery: currentQuery)
        synchronizer.load()
        ThreadUtils.delay(seconds: 0.5)
        coreDataHelper.performAndWait {}

        XCTAssertEqual(currentQuery, generalInfoStorage.getSplitsFilterQueryString(),
                       "precondition: filter change was processed")
        XCTAssertEqual(-1, database.generalInfoDao.longValue(info: .splitsChangeNumber),
                       "filter removed but splits cn was kept, next sync would be a delta")
    }

    // MARK: - Helpers

    /// Persists one flag in set "a" at cn 100, and the stored filter/flags spec the SDK had before.
    private func seedCache(storedQuery: String) throws {
        let split = TestingHelper.buildSplit(name: "flag_a", treatment: "on")
        split.sets = ["a"]
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: [split],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: Date.now()))
        generalInfoStorage.setFlagSpec(flagsSpec: flagsSpec)
        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: storedQuery)
        coreDataHelper.performAndWait {}

        XCTAssertEqual(1, database.splitDao.getAll().count, "precondition: flag not persisted")
        XCTAssertEqual(100, database.generalInfoDao.longValue(info: .splitsChangeNumber),
                       "precondition: cn not seeded")
    }

    private func queryString(for filters: [SplitFilter]) throws -> String {
        let filterBuilder = FilterBuilder(flagSetsValidator: DefaultFlagSetsValidator(telemetryProducer: telemetryStub))
        return try filterBuilder.add(filters: filters).build()
    }

    private func makeSynchronizer(currentFilters: [SplitFilter], currentQuery: String) -> FeatureFlagsSynchronizer {
        let splitConfig = SplitClientConfig()
        let builder = SyncConfig.builder()
        for filter in currentFilters {
            builder.addSplitFilter(filter)
        }
        splitConfig.sync = builder.build()

        let storageContainer = SplitStorageContainer(
            splitDatabase: database,
            splitsStorage: splitsStorage,
            persistentSplitsStorage: persistentSplitsStorage,
            impressionsStorage: ImpressionsStorageStub(),
            persistentImpressionsStorage: PersistentImpressionsStorageStub(),
            impressionsCountStorage: PersistentImpressionsCountStorageStub(),
            eventsStorage: EventsStorageStub(),
            persistentEventsStorage: PersistentEventsStorageStub(),
            telemetryStorage: telemetryStub,
            mySegmentsStorage: MySegmentsStorageStub(),
            myLargeSegmentsStorage: MySegmentsStorageStub(),
            attributesStorage: AttributesStorageStub(),
            uniqueKeyStorage: PersistentUniqueKeyStorageStub(),
            flagSetsCache: FlagSetsCacheMock(),
            persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
            hashedImpressionsStorage: HashedImpressionsStorageMock(),
            generalInfoStorage: generalInfoStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            persistentRuleBasedSegmentsStorage: DefaultPersistentRuleBasedSegmentsStorage(
                database: database, generalInfoStorage: generalInfoStorage),
            targetingRulesPersistenceBreaker: DefaultPersistenceBreaker())

        let syncWorkerFactory = SyncWorkerFactoryStub()
        syncWorkerFactory.splitsSyncWorker = RetryableSyncWorkerStub()
        syncWorkerFactory.periodicSplitsSyncWorker = PeriodicSyncWorkerStub()

        return DefaultFeatureFlagsSynchronizer(
            splitConfig: splitConfig,
            storageContainer: storageContainer,
            syncWorkerFactory: syncWorkerFactory,
            broadcasterChannel: SyncEventBroadcasterStub(),
            splitsFilterQueryString: currentQuery,
            flagsSpec: flagsSpec,
            splitEventsManager: SplitEventsManagerStub(),
            timeChecker: TimeChecker.forTesting())
    }
}

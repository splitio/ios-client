//
//  CacheIntegrityResyncTest.swift
//  SplitTests
//
//  A persisted cache can be left in a state that cannot be detected locally (e.g. only some
//  definitions stored with a change number > -1). When `cacheIntegrityVersion` is bumped, the
//  first init of an SDK carrying the new value resets the cache once, forcing a full resync.
//

import XCTest
@testable import Split

final class CacheIntegrityResyncTest: XCTestCase {

    private var database: SplitDatabase!
    private var coreDataHelper: CoreDataHelper!
    private var generalInfoStorage: GeneralInfoStorage!
    private var splitsStorage: DefaultSplitsStorage!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!

    override func setUp() {
        let dbName = UUID().uuidString
        coreDataHelper = IntegrationCoreDataHelper.get(databaseName: dbName,
                                                       dispatchQueue: DispatchQueue(label: dbName,
                                                                                    target: DispatchQueue.test))
        database = TestingHelper.createTestDatabase(name: dbName, helper: coreDataHelper)
        generalInfoStorage = DefaultGeneralInfoStorage(database: database)
        splitsStorage = DefaultSplitsStorage(
            persistentSplitsStorage: DefaultPersistentSplitsStorage(database: database),
            flagSetsCache: DefaultFlagSetsCache(setsInFilter: nil),
            generalInfoStorage: generalInfoStorage,
            persistenceBreaker: DefaultPersistenceBreaker())
        ruleBasedSegmentsStorage = DefaultRuleBasedSegmentsStorage(
            persistentStorage: DefaultPersistentRuleBasedSegmentsStorage(database: database,
                                                                          generalInfoStorage: generalInfoStorage),
            generalInfoStorage: generalInfoStorage)
    }

    /// Partially populated cache (one flag, cn > -1) from an older SDK: reset once, so the next sync is since=-1.
    func testPartialCacheFromOlderSdkIsResetOnce() {
        preloadPartialCache()

        validateCache()

        XCTAssertEqual(0, database.splitDao.getAll().count)
        XCTAssertEqual(-1, database.generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(0, database.ruleBasedSegmentDao.getAll().count)
        XCTAssertEqual(-1, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
        XCTAssertEqual(DefaultRolloutCacheManager.cacheIntegrityVersion, generalInfoStorage.getCacheIntegrityVersion())
        XCTAssertTrue(generalInfoStorage.getRolloutCacheLastClearTimestamp() > 0)

        // Data stored after the reset is kept on later inits.
        preloadPartialCache()
        validateCache()
        XCTAssertEqual(1, database.splitDao.getAll().count)
        XCTAssertEqual(100, database.generalInfoDao.longValue(info: .splitsChangeNumber))
    }

    /// Only the rule-based segments cache has a change number: still repaired.
    func testRuleBasedSegmentsOnlyCacheIsReset() {
        _ = ruleBasedSegmentsStorage.update(
            toAdd: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 50)],
            toRemove: [],
            changeNumber: 50)
        coreDataHelper.performAndWait {}

        validateCache()

        XCTAssertEqual(0, database.ruleBasedSegmentDao.getAll().count)
        XCTAssertEqual(-1, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
        XCTAssertEqual(DefaultRolloutCacheManager.cacheIntegrityVersion, generalInfoStorage.getCacheIntegrityVersion())
    }

    /// Fresh install: nothing to repair, but the version is stamped so a later healthy cache is kept.
    func testEmptyCacheOnlyStampsVersion() {
        validateCache()

        XCTAssertEqual(DefaultRolloutCacheManager.cacheIntegrityVersion, generalInfoStorage.getCacheIntegrityVersion())

        preloadPartialCache()
        validateCache()
        XCTAssertEqual(1, database.splitDao.getAll().count)
    }

    private func preloadPartialCache() {
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: [TestingHelper.buildSplit(name: "flag_a", treatment: "on")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: Date.now()))
        _ = ruleBasedSegmentsStorage.update(
            toAdd: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 50)],
            toRemove: [],
            changeNumber: 50)
        coreDataHelper.performAndWait {}
    }

    private func validateCache() {
        let manager = DefaultRolloutCacheManager(generalInfoStorage: generalInfoStorage,
                                                 rolloutCacheConfiguration: RolloutCacheConfiguration.builder().build(),
                                                 storages: splitsStorage, ruleBasedSegmentsStorage)
        manager.validateCache {}
        coreDataHelper.performAndWait {}
    }
}

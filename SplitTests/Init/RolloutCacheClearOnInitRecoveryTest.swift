//
//  RolloutCacheClearOnInitRecoveryTest.swift
//  SplitTests
//
//  Verifies that RolloutCacheConfiguration.clearOnInit recovers a cache with no flags
//  and a persisted flags change number > -1.
//  Uses the real DefaultSplitsStorage / rule-based storage on a test CoreData DB so
//  the persisted change numbers are really checked.
//

import XCTest
@testable import Split

final class RolloutCacheClearOnInitRecoveryTest: XCTestCase {

    private var database: SplitDatabase!
    private var coreDataHelper: CoreDataHelper!
    private var generalInfoStorage: GeneralInfoStorage!
    private var splitsStorage: DefaultSplitsStorage!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!
    private var fetcher: ScriptedRolloutRecoveryFetcher!

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
        fetcher = ScriptedRolloutRecoveryFetcher()
        // These tests target clearOnInit, not the one-time integrity reset.
        generalInfoStorage.setCacheIntegrityVersion(DefaultRolloutCacheManager.cacheIntegrityVersion)
        coreDataHelper.performAndWait {}
    }

    /// First-time clear: lastRolloutCacheClear is 0, so clearOnInit clears the broken cache.
    /// Then the next sync (since -1) must be a full snapshot that refills the cache.
    func testClearOnInitResetsBrokenCacheAndNextSyncIsFullSnapshot() throws {
        preloadBrokenState(updateTimestamp: Date.now())
        assertBrokenState(changeNumber: 100, rbsChangeNumber: 50)

        runValidateCache(clearOnInit: true)

        XCTAssertEqual(-1, splitsStorage.changeNumber, "in-memory flags change number not reset")
        XCTAssertEqual(-1, database.generalInfoDao.longValue(info: .splitsChangeNumber),
                       "persisted flags change number not reset")
        XCTAssertEqual(0, database.splitDao.getAll().count)
        XCTAssertEqual(-1, generalInfoStorage.getRuleBasedSegmentsChangeNumber(),
                       "persisted RBS change number not reset")
        XCTAssertEqual(0, database.ruleBasedSegmentDao.getAll().count)
        XCTAssertGreaterThan(generalInfoStorage.getRolloutCacheLastClearTimestamp(), 0)

        // Next sync starts from -1, so the backend must return a full snapshot.
        fetcher.responses = [
            TargetingRulesChange(
                featureFlags: SplitChange(splits: [TestingHelper.buildSplit(name: "flag_a", treatment: "on")],
                                          since: -1, till: 200),
                ruleBasedSegments: RuleBasedSegmentChange(
                    segments: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 60)],
                    since: -1, till: 60)),
            // Follow-up request from since 200 / rbSince 60 returns an empty delta.
            TargetingRulesChange(
                featureFlags: SplitChange(splits: [], since: 200, till: 200),
                ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: 60, till: 60))
        ]
        _ = try makeSyncHelper().sync(since: splitsStorage.changeNumber,
                                      rbSince: ruleBasedSegmentsStorage.changeNumber)
        flush()

        XCTAssertEqual(-1, fetcher.requestedSince.first)
        XCTAssertEqual(200, fetcher.requestedSince.last)
        XCTAssertEqual(1, database.splitDao.getAll().count)
        XCTAssertEqual(200, database.generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(1, database.ruleBasedSegmentDao.getAll().count)
        XCTAssertEqual(60, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
    }

    /// Control: without clearOnInit the broken state is kept on init.
    func testWithoutClearOnInitBrokenStateIsKept() {
        preloadBrokenState(updateTimestamp: Date.now())

        runValidateCache(clearOnInit: false)

        assertBrokenState(changeNumber: 100, rbsChangeNumber: 50)
    }

    /// Caveat: clearOnInit does not clear again if the cache was cleared less than kMinCacheClearDays (1 day) ago.
    func testClearOnInitIsSkippedWhenClearedWithinLastDay() {
        preloadBrokenState(updateTimestamp: Date.now())
        let recentClear = Date.now()
        generalInfoStorage.setRolloutCacheLastClearTimestamp(timestamp: recentClear)
        flush()

        runValidateCache(clearOnInit: true)

        assertBrokenState(changeNumber: 100, rbsChangeNumber: 50)
        XCTAssertEqual(recentClear, generalInfoStorage.getRolloutCacheLastClearTimestamp())
    }

    /// clearOnInit clears again once the last clear is at least one day old.
    func testClearOnInitClearsAgainAfterOneDay() {
        preloadBrokenState(updateTimestamp: Date.now())
        generalInfoStorage.setRolloutCacheLastClearTimestamp(timestamp: Date.now() - 2 * 86400)
        flush()

        runValidateCache(clearOnInit: true)

        XCTAssertEqual(-1, database.generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(-1, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
    }

    // MARK: - Helpers

    /// A cache with no flags, no rule-based segments and change numbers > -1.
    /// Update timestamp is recent, so the expiration path does not fire.
    private func preloadBrokenState(updateTimestamp: Int64) {
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                                   archivedSplits: [],
                                                                   changeNumber: 100,
                                                                   updateTimestamp: updateTimestamp))
        _ = ruleBasedSegmentsStorage.update(toAdd: [], toRemove: [], changeNumber: 50)
        flush()
    }

    private func assertBrokenState(changeNumber: Int64, rbsChangeNumber: Int64) {
        XCTAssertEqual(0, database.splitDao.getAll().count, "flags should be empty")
        XCTAssertEqual(changeNumber, database.generalInfoDao.longValue(info: .splitsChangeNumber),
                       "persisted flags change number")
        XCTAssertEqual(0, database.ruleBasedSegmentDao.getAll().count, "RBS should be empty")
        XCTAssertEqual(rbsChangeNumber, generalInfoStorage.getRuleBasedSegmentsChangeNumber(),
                       "persisted RBS change number")
    }

    private func runValidateCache(clearOnInit: Bool) {
        let config = RolloutCacheConfiguration.builder().set(clearOnInit: clearOnInit).build()
        let manager = DefaultRolloutCacheManager(generalInfoStorage: generalInfoStorage,
                                                 rolloutCacheConfiguration: config,
                                                 storages: splitsStorage, ruleBasedSegmentsStorage)
        var listenerCalled = false
        manager.validateCache { listenerCalled = true }
        XCTAssertTrue(listenerCalled)
        flush()
    }

    private func makeSyncHelper() -> SplitsSyncHelper {
        return SplitsSyncHelper(splitFetcher: fetcher,
                                splitsStorage: splitsStorage,
                                ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
                                ruleBasedSegmentsChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
                                generalInfoStorage: generalInfoStorage,
                                splitConfig: SplitClientConfig())
    }

    /// Waits for pending CoreData writes queued on the test database context.
    private func flush() {
        coreDataHelper.performAndWait {}
    }
}

/// Scripted HttpSplitFetcher that returns queued responses in order, like a backend answering
/// successive requests (the sync loop keeps fetching until since == till).
fileprivate final class ScriptedRolloutRecoveryFetcher: HttpSplitFetcher, @unchecked Sendable {
    var responses: [TargetingRulesChange] = []
    private(set) var requestedSince: [Int64] = []

    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders?, spec: String?) throws -> TargetingRulesChange {
        requestedSince.append(since)
        guard !responses.isEmpty else {
            throw GenericError.unknown(message: "no scripted change")
        }
        return responses.removeFirst()
    }
}

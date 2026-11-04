//
//  SplitsProxyRecoveryRegressionTest.swift
//  SplitTests
//
//  Regression guard for the proxy-recovery bug seen on 3.7.x: after an outdated-proxy
//  recovery sync the cache was cleared but only a delta was requested, leaving no flags
//  with a change number > -1. Since the fix (PR #851), recovery must request a full
//  snapshot (since = -1, rbSince = -1) so unchanged flags are restored.
//
//  On 3.7.x this test fails at the first `since == -1` assertion.
//

import XCTest
@testable import Split

final class SplitsProxyRecoveryRegressionTest: XCTestCase {

    private var database: SplitDatabase!
    private var coreDataHelper: CoreDataHelper!
    private var generalInfoStorage: GeneralInfoStorage!
    private var splitsStorage: DefaultSplitsStorage!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!
    private var fetcher: ScriptedProxyReproFetcher!

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
        fetcher = ScriptedProxyReproFetcher()
    }

    /// proxy error -> (>1h later) recovery sync. The server only returns unchanged
    /// definitions for a full snapshot (since = -1), like a real server does.
    /// Expected: recovery requests since = -1 and the flag and segment are restored.
    func testProxyRecoveryRefetchesFullSnapshotAndKeepsFlags() throws {
        // 1. Preload cache: one flag at cn 100, one rule-based segment at cn 50.
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: [TestingHelper.buildSplit(name: "flag_a", treatment: "on")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: Date.now()))
        _ = ruleBasedSegmentsStorage.update(
            toAdd: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 50)],
            toRemove: [],
            changeNumber: 50)
        flush()
        XCTAssertEqual(1, database.splitDao.getAll().count, "precondition: flag not preloaded")
        XCTAssertEqual(100, database.generalInfoDao.longValue(info: .splitsChangeNumber))

        // 2. First sync fails with an outdated-proxy error; proxy timestamp is stored.
        fetcher.nextError = HttpError.outdatedProxyError(code: -1005, spec: "1.3")
        let firstHelper = makeSyncHelper()
        XCTAssertThrowsError(try firstHelper.sync(since: 100, rbSince: 50)) { error in
            guard case HttpError.outdatedProxyError = error else {
                XCTFail("expected outdatedProxyError, got \(error)")
                return
            }
        }
        flush()

        // 3. Simulate the SDK running again more than proxyCheckIntervalMillis (1h) later.
        //    A fresh helper is used because the handler caches the timestamp in memory.
        generalInfoStorage.setLastProxyUpdateTimestamp(Date.nowMillis() - 3_700_000)
        flush()

        // 4. Recovery sync. Server: full snapshot for since = -1, empty delta otherwise.
        fetcher.nextError = nil
        fetcher.respond = { [weak self] since, rbSince in
            guard let self = self else { fatalError("test deallocated") }
            return since == -1 ? self.fullSnapshot() : self.emptyDelta(flagsTill: 100, rbsTill: 50)
        }
        let firstRecoveryRequest = fetcher.requestedSince.count
        let recoveryHelper = makeSyncHelper()
        let result = try recoveryHelper.sync(since: 100, rbSince: 50)
        flush()

        XCTAssertEqual(-1, fetcher.requestedSince[firstRecoveryRequest],
                       "recovery must request a full snapshot, not the stored since")
        XCTAssertEqual(-1, fetcher.requestedRbSince[firstRecoveryRequest],
                       "recovery must request a full rule-based segments snapshot")
        XCTAssertTrue(result.success)

        // The flag and segment survive the recovery, with a valid change number.
        XCTAssertNotNil(splitsStorage.get(name: "flag_a"), "in-memory flag lost during recovery")
        XCTAssertEqual(1, database.splitDao.getAll().count, "persisted flag lost during recovery")
        XCTAssertEqual(100, splitsStorage.changeNumber)
        XCTAssertEqual(100, database.generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(1, database.ruleBasedSegmentDao.getAll().count, "persisted RBS lost during recovery")
        XCTAssertEqual(50, ruleBasedSegmentsStorage.changeNumber)

        // 5. A later delta sync keeps the cache intact.
        let laterHelper = makeSyncHelper()
        _ = try laterHelper.sync(since: 100, rbSince: 50)
        flush()
        XCTAssertEqual(100, fetcher.requestedSince.last)
        XCTAssertEqual(1, database.splitDao.getAll().count)
        XCTAssertEqual(1, database.ruleBasedSegmentDao.getAll().count)
    }

    // MARK: - Helpers

    private func makeSyncHelper() -> SplitsSyncHelper {
        return SplitsSyncHelper(splitFetcher: fetcher,
                                splitsStorage: splitsStorage,
                                ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
                                ruleBasedSegmentsChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
                                generalInfoStorage: generalInfoStorage,
                                splitConfig: SplitClientConfig())
    }

    private func fullSnapshot() -> TargetingRulesChange {
        return TargetingRulesChange(
            featureFlags: SplitChange(splits: [TestingHelper.buildSplit(name: "flag_a", treatment: "on")],
                                      since: -1, till: 100),
            ruleBasedSegments: RuleBasedSegmentChange(
                segments: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 50)],
                since: -1, till: 50))
    }

    private func emptyDelta(flagsTill: Int64, rbsTill: Int64) -> TargetingRulesChange {
        return TargetingRulesChange(
            featureFlags: SplitChange(splits: [], since: flagsTill, till: flagsTill),
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: rbsTill, till: rbsTill))
    }

    /// Waits for pending CoreData writes queued on the test database context.
    private func flush() {
        coreDataHelper.performAndWait {}
    }
}

/// Scripted HttpSplitFetcher: throws `nextError` if set, otherwise answers with `respond`.
fileprivate final class ScriptedProxyReproFetcher: HttpSplitFetcher, @unchecked Sendable {
    var nextError: Error?
    var respond: ((Int64, Int64?) -> TargetingRulesChange)?
    private(set) var requestedSince: [Int64] = []
    private(set) var requestedRbSince: [Int64?] = []

    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders?, spec: String?) throws -> TargetingRulesChange {
        requestedSince.append(since)
        requestedRbSince.append(rbSince)
        if let error = nextError {
            throw error
        }
        guard let respond = respond else {
            throw GenericError.unknown(message: "no scripted response")
        }
        return respond(since, rbSince)
    }
}

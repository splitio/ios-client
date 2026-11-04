//
//  ProxyRecoveryTransportErrorTest.swift
//  SplitTests
//
//  End-to-end regression guard for the proxy-recovery bug seen on 3.7.x, driven by a REAL
//  transport-level -1005 (not a -1005 status code) on a custom sdkEndpoint:
//  DefaultRestClient -> DefaultHttpSplitFetcher -> SplitsSyncHelper.sync -> recovery.
//  Since the fix (PR #851), the recovery sync must request a full snapshot
//  (since = -1, rbSince = -1) so unchanged flags and segments are restored.
//
//  On 3.7.x this test fails at the first `since == -1` assertion.
//

import XCTest
@testable import Split

final class ProxyRecoveryTransportErrorTest: XCTestCase {

    private struct SplitChangesRequest {
        let since: Int64
        let rbSince: Int64
    }

    private var database: SplitDatabase!
    private var coreDataHelper: CoreDataHelper!
    private var generalInfoStorage: GeneralInfoStorage!
    private var splitsStorage: DefaultSplitsStorage!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!
    private var restClient: DefaultRestClient!
    private var fetcher: DefaultHttpSplitFetcher!

    private let lock = NSLock()
    private var requests = [SplitChangesRequest]()
    private var failWithTransportError = true
    private var previousSpec = Spec.flagsSpec

    override func setUp() {
        super.setUp()
        previousSpec = Spec.flagsSpec
        Spec.flagsSpec = "1.3"
        failWithTransportError = true
        requests = []

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

        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatch,
                                                          streamingHandler: { request in
            XCTFail("Streaming should not be used")
            return TestStreamResponseBinding.createFor(request: request, code: 200)
        })
        let httpClient = DefaultHttpClient(session: HttpSessionMock(), requestManager: reqManager)
        let endpoints = ServiceEndpoints.builder().set(sdkEndpoint: "https://testing.split.io").build()
        restClient = DefaultRestClient(httpClient: httpClient,
                                       endpointFactory: EndpointFactory(serviceEndpoints: endpoints,
                                                                        apiKey: IntegrationHelper.dummyApiKey,
                                                                        splitsQueryString: ""),
                                       reachabilityChecker: ReachabilityMock())
        fetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                          syncHelper: DefaultSyncHelper(telemetryProducer: nil),
                                          timeChecker: TimeChecker.forTesting())
    }

    override func tearDown() {
        Spec.flagsSpec = previousSpec
        super.tearDown()
    }

    func testTransportErrorOnCustomEndpointThenRecoveryRefetchesFullSnapshot() throws {
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

        // 2. First sync: real transport-level -1005 on the custom endpoint.
        failWithTransportError = true
        XCTAssertThrowsError(try makeSyncHelper().sync(since: 100, rbSince: 50)) { error in
            guard case HttpError.outdatedProxyError = error else {
                XCTFail("expected outdatedProxyError, got \(error)")
                return
            }
        }
        flush()
        XCTAssertGreaterThan(generalInfoStorage.getLastProxyUpdateTimestamp(), 0,
                             "proxy error timestamp not persisted")
        XCTAssertEqual(1, requestsSnapshot().count, "precondition: exactly one failed request")

        // 3. More than the 1h check interval later. A fresh helper is needed because the
        //    handler caches the timestamp in memory after trackProxyError().
        generalInfoStorage.setLastProxyUpdateTimestamp(Date.nowMillis() - 3_700_000)
        flush()

        // 4. Recovery sync against a server that behaves like a real one.
        failWithTransportError = false
        let firstRecoveryIndex = requestsSnapshot().count
        let result = try makeSyncHelper().sync(since: 100, rbSince: 50)
        flush()

        // 5. Fixed behaviour.
        let recoveryRequests = requestsSnapshot()
        XCTAssertGreaterThan(recoveryRequests.count, firstRecoveryIndex, "no recovery request was made")
        guard recoveryRequests.count > firstRecoveryIndex else { return }
        XCTAssertEqual(-1, recoveryRequests[firstRecoveryIndex].since,
                       "recovery must request a full snapshot, not the stored since")
        XCTAssertEqual(-1, recoveryRequests[firstRecoveryIndex].rbSince,
                       "recovery must request a full rule-based segments snapshot")
        XCTAssertTrue(result.success)
        XCTAssertNotNil(splitsStorage.get(name: "flag_a"), "in-memory flag lost during recovery")
        XCTAssertEqual(1, database.splitDao.getAll().count, "persisted flag lost during recovery")
        XCTAssertEqual(100, splitsStorage.changeNumber)
        XCTAssertEqual(100, database.generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(1, database.ruleBasedSegmentDao.getAll().count, "persisted RBS lost during recovery")
        XCTAssertEqual(50, ruleBasedSegmentsStorage.changeNumber)
    }

    // MARK: - Helpers

    /// Scripted server. Never returns the full snapshot for since != -1 (would loop fetchUntil forever).
    private func dispatch(_ request: HttpDataRequest) -> TestDispatcherResponse {
        guard request.isSplitEndpoint() else {
            return TestDispatcherResponse(code: 500)
        }
        let since = queryValue("since", in: request.url) ?? -1
        let rbSince = queryValue("rbSince", in: request.url) ?? -1
        lock.lock()
        requests.append(SplitChangesRequest(since: since, rbSince: rbSince))
        let fail = failWithTransportError
        lock.unlock()

        if fail {
            // Status code 0 + transport error: reaches HttpDataRequest's errorHandler path.
            return TestDispatcherResponse(code: 0, data: nil, error: HttpError.networkLost(code: -1005))
        }
        let body = since == -1 ? fullSnapshotJson() : emptyDeltaJson()
        return TestDispatcherResponse(code: 200, data: Data(body.utf8))
    }

    private func queryValue(_ name: String, in url: URL) -> Int64? {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        return items?.first(where: { $0.name == name })?.value.flatMap { Int64($0) }
    }

    private func requestsSnapshot() -> [SplitChangesRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    /// Empty delta: flags unchanged at cn 100, rule-based segments unchanged at cn 50.
    private func emptyDeltaJson() -> String {
        return "{\"ff\": {\"d\":[], \"s\": 100, \"t\": 100}, \"rbs\": {\"d\":[], \"s\": 50, \"t\": 50}}"
    }

    private func fullSnapshotJson() -> String {
        let change = TargetingRulesChange(
            featureFlags: SplitChange(splits: [TestingHelper.buildSplit(name: "flag_a", treatment: "on")],
                                      since: -1, till: 100),
            ruleBasedSegments: RuleBasedSegmentChange(
                segments: [TestingHelper.createRuleBasedSegment(name: "rbs_a", changeNumber: 50)],
                since: -1, till: 50))
        return try! Json.encodeToJson(change)
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

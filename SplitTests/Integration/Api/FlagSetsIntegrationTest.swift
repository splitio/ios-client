//
//  SplitIntegrationTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class FlagSetsIntegrationTests: XCTestCase {

    struct Status {
        static let active = "ACTIVE"
        static let archived = "ARCHIVED"
    }

    let apiKey = IntegrationHelper.dummyApiKey
    let matchingKey = IntegrationHelper.dummyUserKey
    let trafficType = "account"
    let kNeverRefreshRate = 9999999
    var splitChange: TargetingRulesChange?
    var testDb: SplitDatabase!

    var querystring = ""
    var splitChangesHit = 0

    var mySegmentsJson: String!

    var streamingBinding: TestStreamResponseBinding?

    var httpClient: HttpClient!

    var telemetryConfigSent: TelemetryConfig?
    var telemetryStatsSent: TelemetryStats?

    var telemetryConfigExp: XCTestExpectation?
    var telemetryStatsExp: XCTestExpectation?
    var sseExp: XCTestExpectation?

    var firstConfig = true
    var firstStats = true

    var changeFlagSetsJson: String = ""
    var pollingFlagSetsHits: [Data]!
    var pollingExps: [XCTestExpectation]!

    var streamingHelper: StreamingTestingHelper!

    var factory: SplitFactory!

    override func setUp() {
        let segments = ["segment1", "segment2"]
        mySegmentsJson = IntegrationHelper.buildSegments(regular: segments)
        Spec.flagsSpec = ""
        testDb = TestingHelper.createTestDatabase(name: "GralIntegrationTest")
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        testDb.mySegmentsDao.update(userKey: matchingKey, change: SegmentChange(segments: segments))
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let urlString = request.url.absoluteString
                if self.splitChangesHit == 0 {
                    if let ind = urlString.firstIndex(of: "?") {
                        let qstr = urlString.suffix(from: urlString.index(after: ind)).asString()
                        self.querystring = qstr
                    }
                }
                self.splitChangesHit+=1
                return TestDispatcherResponse(code: 200, data: try? Json.encodeToJsonData(self.splitChange))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(self.mySegmentsJson.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isTelemetryConfigEndpoint() {
                if !self.firstConfig {
                    return TestDispatcherResponse(code: 200)
                }
                self.firstConfig = false
                if let json = request.body?.stringRepresentation {
                    self.telemetryConfigSent = try? Json.decodeFrom(json: json, to: TelemetryConfig.self)
                }
                self.telemetryConfigExp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }

            if request.isTelemetryUsageEndpoint() {

                if !self.firstStats {
                    return TestDispatcherResponse(code: 200)
                }
                self.firstStats = false
                if let json = request.body?.stringRepresentation {
                    self.telemetryStatsSent = try? Json.decodeFrom(json: json, to: TelemetryStats.self)
                }
                self.telemetryStatsExp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildPollingTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.splitChangesHit < 3 {
                    let change = self.pollingFlagSetsHits[self.splitChangesHit]
                    if self.splitChangesHit > 0 {
                        self.pollingExps![self.splitChangesHit - 1].fulfill()
                    }
                    self.splitChangesHit+=1
                    return TestDispatcherResponse(code: 200, data: change)
                }
                self.splitChangesHit+=1
                return TestDispatcherResponse(code: 200, data: IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).dataBytes)
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(self.mySegmentsJson.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingHelper.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp?.fulfill()
            return self.streamingHelper.streamingBinding!
        }
    }

    func testInitialQuerystring() throws {
        let syncConfig = SyncConfig.builder()
                   .addSplitFilter(SplitFilter.bySet(["set_x", "set_x", "set_3"]))
                   .addSplitFilter(SplitFilter.bySet(["set_2", "set_3", "set_ww", "invalid+"]))
                   .build()

        try bodyTest(syncConfig: syncConfig)

        XCTAssertEqual("since=-1&rbSince=-1&sets=set_2,set_3,set_ww,set_x", querystring)
    }

    func testInitialQuerystringWithSpec() throws {
        Spec.flagsSpec = "1.1"
        let syncConfig = SyncConfig.builder()
                   .addSplitFilter(SplitFilter.bySet(["set_x", "set_x", "set_3"]))
                   .addSplitFilter(SplitFilter.bySet(["set_2", "set_3", "set_ww", "invalid+"]))
                   .build()

        try bodyTest(syncConfig: syncConfig)

        XCTAssertEqual("s=1.1&since=-1&rbSince=-1&sets=set_2,set_3,set_ww,set_x", querystring)
    }

    func testTotalAndInvalidFlagSetsTelemetry() throws {

        let syncConfig = SyncConfig.builder()
                   .addSplitFilter(SplitFilter.bySet(["a", "_b", "a", "a", "c"]))
                   .addSplitFilter(SplitFilter.bySet(["d", "_d"]))
                   .build()

        telemetryConfigExp = XCTestExpectation()
        try bodyTest(syncConfig: syncConfig, telemetryEnabled: true)

        wait(for: [telemetryConfigExp!], timeout: 3)

        XCTAssertEqual("since=-1&rbSince=-1&sets=a,c,d", querystring)
        XCTAssertEqual(7, telemetryConfigSent?.flagSetsTotal ?? -1)
        XCTAssertEqual(4, telemetryConfigSent?.flagSetsInvalid ?? -1)
    }

    func testTelemetryStats() throws {
        
        var expLatencies = Array.init(repeating: 0, count: 23)
        expLatencies[0] = 1

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set1", "set2", "set10", "set20"]))
            .addSplitFilter(SplitFilter.bySet(["nset1", "nset2", "c"]))
            .build()

        telemetryStatsExp = XCTestExpectation()
        let client = try startTest(syncConfig: syncConfig, telemetryEnabled: true)

        _ = client?.getTreatmentsByFlagSet("set2", attributes: nil)
        _ = client?.getTreatmentsByFlagSets(["set10", "set20"], attributes: nil)
        _ = client?.getTreatmentsWithConfigByFlagSet("set2", attributes: nil)
        _ = client?.getTreatmentsWithConfigByFlagSets(["set1", "set2"], attributes: nil)

        client?.flush()


        wait(for: [telemetryStatsExp!], timeout: 3)

        destroyTest(client: client)

        XCTAssertEqual("since=-1&rbSince=-1&sets=c,nset1,nset2,set1,set10,set2,set20", querystring)
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsByFlagSet ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsByFlagSets ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsWithConfigByFlagSet ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsWithConfigByFlagSets ?? [])

    }

    func testPollingWithSets() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())

        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 100, till: 100,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 200, till: 200,
                                                      sets1: ["set_1"],
                                                      sets2: ["set_2"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 300, till: 300,
                                                      sets1: ["set_3"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_2"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"),
                       XCTestExpectation(description: "EXP_P1"),
                       XCTestExpectation(description: "EXP_P2")]

        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        let client = try startTest(syncConfig: syncConfig, refreshRate: 2)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        let dbExp2Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.update)
        let dbExp2Ins = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        // Wait for db update
        wait(for: [pollingExps![0], dbExp2Ins, dbExp2Upd], timeout: 3)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        let dbExp3Del = IntegrationCoreDataHelper.getDbExp(count: 2, entity: .split, operation: CrudKey.delete)
        let dbExp3Ins = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)
        wait(for: [pollingExps![1], dbExp3Ins, dbExp3Del], timeout: 3)

        let split1Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(1, split1Change01)
        XCTAssertEqual(0, split2Change01)
        XCTAssertEqual(0, split3Change01)

        XCTAssertEqual(1, split1Change02)
        XCTAssertEqual(1, split2Change02)
        XCTAssertEqual(0, split3Change02)

        XCTAssertEqual(0, split1Change03)
        XCTAssertEqual(0, split2Change03)
        XCTAssertEqual(1, split3Change03)
    }

    func testPollingNoSets() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 100, till: 100,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 200, till: 200,
                                                      sets1: ["set_1"],
                                                      sets2: ["set_2"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 300, till: 300,
                                                      sets1: ["set_3"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_2"],
                                                      archived: [Status.active, Status.active, Status.archived])!
        ]

        pollingExps = [XCTestExpectation(), XCTestExpectation(), XCTestExpectation()]

        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 3, entity: .split, operation: CrudKey.insert)

        let client = try startTest(syncConfig: nil, refreshRate: 2)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change01 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        let dbExp2Upd = IntegrationCoreDataHelper.getDbExp(count: 3, entity: .split, operation: CrudKey.update)

        // Wait for db update
        wait(for: [pollingExps![0], dbExp2Upd], timeout: 3)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change02 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        let dbExp3Upd = IntegrationCoreDataHelper.getDbExp(count: 2, entity: .split, operation: CrudKey.update)
        let dbExp3Del = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.delete)
        wait(for: [pollingExps![1], dbExp3Upd, dbExp3Del], timeout: 3)

        let split1Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_1" }.count
        let split2Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_2" }.count
        let split3Change03 = testDb.splitDao.getAll().filter { $0.name == "SPLIT_3" }.count

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(1, split1Change01)
        XCTAssertEqual(1, split2Change01)
        XCTAssertEqual(1, split3Change01)

        XCTAssertEqual(1, split1Change02)
        XCTAssertEqual(1, split2Change02)
        XCTAssertEqual(1, split3Change02)

        XCTAssertEqual(1, split1Change03)
        XCTAssertEqual(1, split2Change03)
        XCTAssertEqual(0, split3Change03)
    }

    func testStreamingNoFilter() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 100, till: 100,
                                                      sets1: ["set_1", "set_20"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"],
                                                      names: ["mauro_java", "sp1", "sp2"])!,
                                getChangeFlagSetsJson(since: 200, till: 200,
                                                      sets1: ["set_20"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"],
                                                      names: ["mauro_java", "sp1", "sp2"])!,
                                getChangeFlagSetsJson(since: 300, till: 300,
                                                      sets1: [],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"],
                                                      names: ["mauro_java", "sp1", "sp2"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"), XCTestExpectation(description: "EXP_P1")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 3, entity: .split, operation: CrudKey.insert)

        let client = try startTest(syncConfig: nil)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "mauro_java" }[0]

        let dbExp2Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.update)
        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0], dbExp2Upd], timeout: 3)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "mauro_java" }[0]


        let dbExp3Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.update)
        streamingHelper.pushSplitsMessage(TestingData.escapedUpdateSplitsNotificationGzip(pcn: 200))

        wait(for: [dbExp3Upd], timeout: 3)

        let split1Change03 = testDb.splitDao.getAll().filter { $0.name == "mauro_java" }[0]

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(["set_1", "set_20"], split1Change01.sets?.sorted())
        XCTAssertEqual(["set_20"], split1Change02.sets?.sorted())
        XCTAssertNil(split1Change03.sets)
    }

    func testStreamingFilterDeleteEmptySets() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"), XCTestExpectation(description: "EXP_P1")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        let client = try startTest(syncConfig: syncConfig)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "workm" }


        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0]], timeout: 3)

        // Update sets again (set_1, set_2)
        let dbExp3Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotification2)

        wait(for: [dbExp3Upd], timeout: 3)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "workm" }[0]

        // Update sets again (only set_1)
        let dbExp4Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.update)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotification3)

        wait(for: [dbExp4Upd], timeout: 3)

        let split1Change03 = testDb.splitDao.getAll().filter { $0.name == "workm" }[0]

        // Update sets to empty
        let dbExp5Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.delete)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotification4None)
        wait(for: [dbExp5Upd], timeout: 3)

        let split1Change04 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(0, split1Change01.count)
        XCTAssertEqual(["set_1", "set_2"], split1Change02.sets?.sorted())
        XCTAssertEqual(["set_1"], split1Change03.sets?.sorted())
        XCTAssertEqual(0, split1Change04.count)
    }

    func testStreamingFilterKill() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 4, till: 4,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"), 
                       XCTestExpectation(description: "EXP_P1"),
                       XCTestExpectation(description: "EXP_P2")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        let client = try startTest(syncConfig: syncConfig)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0]], timeout: 3)

        // Update sets again (set_1, set_2)
        let dbExp3Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotification2)

        wait(for: [dbExp3Upd], timeout: 3)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "workm" }[0]

        // Update sets to empty
        let dbExp5Upd = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.update)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotificationKill)
        wait(for: [dbExp5Upd, pollingExps![1]], timeout: 3)

        let split1Change04 = testDb.splitDao.getAll().filter { $0.name == "workm" }[0]

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(0, split1Change01.count)
        XCTAssertEqual(["set_1", "set_2"], split1Change02.sets?.sorted())
        XCTAssertTrue(split1Change04.killed ?? false)
    }

    func testStreamingFilterKillNonExisting() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 4, till: 4,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"),
                       XCTestExpectation(description: "EXP_P1"),
                       XCTestExpectation(description: "EXP_P2")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        let client = try startTest(syncConfig: syncConfig)

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0]], timeout: 3)

        // Kill non existing
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotificationKill)
        wait(for: [pollingExps![1]], timeout: 3)

        let split1Change04 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(0, split1Change01.count)
        XCTAssertEqual(0, split1Change04.count)
    }

    func testFlagsetsSdkUpdateNoFiredWhenFFNotInFilterSets() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["p_set_1", "set2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["p_set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"), XCTestExpectation(description: "EXP_P1")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["p_set_1", "p_set_2"]))
            .build()

        let client = try startTest(syncConfig: syncConfig)

        var sdkUpdateFiredCount = 0
        client?.on(event: .sdkUpdated, runInBackground: true) {
            sdkUpdateFiredCount+=1
        }

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)

        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0]], timeout: 3)
        ThreadUtils.delay(seconds: 2)
        let updateCountBeforeNot = sdkUpdateFiredCount
        // Update sets again (set_1, set_2)
        streamingHelper.pushSplitsMessage(TestingData.kFlagSetsNotification2)

        ThreadUtils.delay(seconds: 2)

        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(0, split1Change01.count)
        XCTAssertEqual(0, split1Change02.count)
        XCTAssertEqual(1, updateCountBeforeNot)
        XCTAssertEqual(1, sdkUpdateFiredCount)
    }

    var client: SplitClient!
    func testFlagsetsSdkUpdateFiredWhenFFInFilterSets() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        streamingHelper = StreamingTestingHelper()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildPollingTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits = [ getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!,

                                getChangeFlagSetsJson(since: 1, till: 1,
                                                      sets1: ["set_1", "set_2"],
                                                      sets2: ["set_3"],
                                                      sets3: ["set_4"])!
        ]

        pollingExps = [XCTestExpectation(description: "EXP_P0"), XCTestExpectation(description: "EXP_P1")]
        IntegrationCoreDataHelper.observeChanges()
        let dbExp1 = IntegrationCoreDataHelper.getDbExp(count: 1, entity: .split, operation: CrudKey.insert)

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        client = try startTest(syncConfig: syncConfig)

        var updExp: XCTestExpectation? = nil
        var sdkUpdateFired = false
        client?.on(event: .sdkUpdated) {
            sdkUpdateFired = true
            updExp?.fulfill()
        }

        // Wait for db update
        wait(for: [dbExp1], timeout: 5)
        let split1Change01 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        streamingHelper.pushKeepalive()

        // Wait for db update
        wait(for: [pollingExps![0]], timeout: 3)

        updExp = XCTestExpectation(description: "SDK update expectation")
        // Update sets again (set_1, set_2)
        streamingHelper.pushSplitsMessage(TestingData.flagSetsNotification(pcn: 1))

        wait(for: [updExp!], timeout: 3)
        let split1Change02 = testDb.splitDao.getAll().filter { $0.name == "workm" }

        destroyTest(client: client)
        IntegrationCoreDataHelper.stopObservingChanges()

        XCTAssertEqual(0, split1Change01.count)
        XCTAssertEqual(1, split1Change02.count)
        XCTAssertTrue(sdkUpdateFired)
    }

    private func bodyTest(syncConfig: SyncConfig, telemetryEnabled: Bool = false) throws {
        let client = try startTest(syncConfig: syncConfig, telemetryEnabled: telemetryEnabled)
        destroyTest(client: client)
    }

    private func startTest(syncConfig: SyncConfig?, 
                           telemetryEnabled: Bool = false,
                           refreshRate: Int = -1) throws -> SplitClient?  {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.sdkReadyTimeOut = 6000
        splitConfig.logLevel = TestingHelper.testLogLevel
        splitConfig.logLevel = .verbose
        splitConfig.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: telemetryEnabled)
        splitConfig.internalTelemetryRefreshRate = 10000

        if refreshRate > -1 {
            splitConfig.streamingEnabled = false
            splitConfig.featuresRefreshRate = refreshRate
        } else {
            sseExp = XCTestExpectation(description: "SSE Expectation")
        }

        if let syncConfig = syncConfig {
            splitConfig.sync = syncConfig
        }

        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(testDb)
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        var expectations = [sdkReadyExpectation]
        if let sseExp = self.sseExp {
            expectations.append(sseExp)
        }
        wait(for: expectations, timeout: 5)

        return client
    }

    private func destroyTest(client: SplitClient?) {
        guard let client = client else { return }
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func loadSplitsChangeFile() -> TargetingRulesChange? {
        let targetingRulesChange = loadSplitChangeFile(name: "splitchanges_1")
        let change = targetingRulesChange?.featureFlags
        change?.since = change?.till ?? -1
        return TargetingRulesChange(featureFlags: change!, ruleBasedSegments: targetingRulesChange!.ruleBasedSegments)
    }

    private func getChangeFlagSetsJson(since: Int64,
                                       till: Int64,
                                       sets1: [String],
                                       sets2: [String],
                                       sets3: [String],
                                       archived: [String]? = nil,
                                       names: [String] = ["SPLIT_1", "SPLIT_2", "SPLIT_3"]) -> Data? {

        

        let nameField1 = "{{SPLIT_NAME_1}}"
        let nameField2 = "{{SPLIT_NAME_2}}"
        let nameField3 = "{{SPLIT_NAME_3}}"
        let setField1 = "{{SPLIT_SETS_1}}"
        let setField2 = "{{SPLIT_SETS_2}}"
        let setField3 = "{{SPLIT_SETS_3}}"
        let sinceField = "{{SINCE}}"
        let tillField = "{{TILL}}"
        let statusField1 = "{{SPLIT_STATUS_1}}"
        let statusField2 = "{{SPLIT_STATUS_2}}"
        let statusField3 = "{{SPLIT_STATUS_3}}"

        let name1Json = names[0]
        let name2Json = names[1]
        let name3Json = names[2]

        let sets1Json = toJsonArray(stringArray: sets1)
        let sets2Json = toJsonArray(stringArray: sets2)
        let sets3Json = toJsonArray(stringArray: sets3)

        let status1Json = archived?[0] ?? Status.active
        let status2Json = archived?[1] ?? Status.active
        let status3Json = archived?[2] ?? Status.active

        let jsonString = changeFlagSetsJson
            .replacingOccurrences(of: nameField1, with: name1Json)
            .replacingOccurrences(of: nameField2, with: name2Json)
            .replacingOccurrences(of: nameField3, with: name3Json)
            .replacingOccurrences(of: setField1, with: sets1Json)
            .replacingOccurrences(of: setField2, with: sets2Json)
            .replacingOccurrences(of: setField3, with: sets3Json)
            .replacingOccurrences(of: statusField1, with: status1Json)
            .replacingOccurrences(of: statusField2, with: status2Json)
            .replacingOccurrences(of: statusField3, with: status3Json)
            .replacingOccurrences(of: sinceField, with: String(since))
            .replacingOccurrences(of: tillField, with: String(till))
        return Data(jsonString.utf8)
    }

    private func loadSplitChangesFlagSetsJson() {
        if let content = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_flagsets", type: "json") {
           changeFlagSetsJson = content
        }
    }

    private func loadSplitChangeFile(name fileName: String) -> TargetingRulesChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change
        }
        return nil
    }

    func toJsonArray(stringArray: [String]) -> String {
        return (try? JSONSerialization.data(withJSONObject: stringArray, options: .prettyPrinted))?.stringRepresentation ?? ""
    }
}

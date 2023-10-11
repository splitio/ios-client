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

    let apiKey = IntegrationHelper.dummyApiKey
    let matchingKey = IntegrationHelper.dummyUserKey
    let trafficType = "account"
    let kNeverRefreshRate = 9999999
    var splitChange: SplitChange?
    var testDb: SplitDatabase!

    var querystring = ""
    var splitChangesHit = 0

    let mySegmentsJson = "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}"

    var streamingBinding: TestStreamResponseBinding?

    var httpClient: HttpClient!

    var telemetryConfigSent: TelemetryConfig?
    var telemetryStatsSent: TelemetryStats?

    var telemetryConfigExp: XCTestExpectation?
    var telemetryStatsExp: XCTestExpectation?

    var firstConfig = true
    var firstStats = true

    var changeFlagSetsJson: String = ""
    var pollingFlagSetsHits: [Data]
    var pollingExps: [XCTestExpectation]?

    override func setUp() {
        testDb = TestingHelper.createTestDatabase(name: "GralIntegrationTest")
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                if self.splitChangesHit == 0 {
                    if let ind = urlString.firstIndex(of: "?") {
                        let qstr = urlString.suffix(from: urlString.index(after: ind)).asString()
                        self.querystring = qstr
                    }
                }
                self.splitChangesHit+=1
                return TestDispatcherResponse(code: 200, data: try? Json.encodeToJsonData(self.splitChange))

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(self.mySegmentsJson.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("testImpressions/bulk"):
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("events/bulk"):
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("metrics/config"):
                if !self.firstConfig {
                    return TestDispatcherResponse(code: 200)
                }
                self.firstConfig = false
                if let json = request.body?.stringRepresentation {
                    self.telemetryConfigSent = try? Json.decodeFrom(json: json, to: TelemetryConfig.self)
                }
                self.telemetryConfigExp?.fulfill()
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("metrics/usage"):
                if !self.firstStats {
                    return TestDispatcherResponse(code: 200)
                }
                self.firstStats = false
                if let json = request.body?.stringRepresentation {
                    self.telemetryStatsSent = try? Json.decodeFrom(json: json, to: TelemetryStats.self)
                }
                self.telemetryStatsExp?.fulfill()
                return TestDispatcherResponse(code: 200)

            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildPollingTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
//                if self.splitChangesHit == 0 {
//                    if let ind = urlString.firstIndex(of: "?") {
//                        let qstr = urlString.suffix(from: urlString.index(after: ind)).asString()
//                        self.querystring = qstr
//                    }
//                }

                if self.splitChangesHit < 3 {
                    let change = self.pollingFlagSetsHits[self.splitChangesHit]
                    self.splitChangesHit+=1
                    return TestDispatcherResponse(code: 200, data: change)
                }
                return TestDispatcherResponse(code: 200, data: IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).dataBytes)

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(self.mySegmentsJson.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            default:
                return TestDispatcherResponse(code: 200)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    func testInitialQuerystring() throws {

        let syncConfig = SyncConfig.builder()
                   .addSplitFilter(SplitFilter.bySet(["set_x", "set_x", "set_3"]))
                   .addSplitFilter(SplitFilter.bySet(["set_2", "set_3", "set_ww", "invalid+"]))
                   .build()

        try bodyTest(syncConfig: syncConfig)

        XCTAssertEqual("since=-1&sets=set_2,set_3,set_ww,set_x", querystring)
    }

    func testTotalAndInvalidFlagSetsTelemetry() throws {

        let syncConfig = SyncConfig.builder()
                   .addSplitFilter(SplitFilter.bySet(["a", "_b", "a", "a", "c"]))
                   .addSplitFilter(SplitFilter.bySet(["d", "_d"]))
                   .build()

        telemetryConfigExp = XCTestExpectation()
        try bodyTest(syncConfig: syncConfig, telemetryEnabled: true)

        wait(for: [telemetryConfigExp!], timeout: 3)

        XCTAssertEqual("since=-1&sets=a,c,d", querystring)
        XCTAssertEqual(5, telemetryConfigSent?.flagSetsTotal ?? -1)
        XCTAssertEqual(2, telemetryConfigSent?.flagSetsInvalid ?? -1)
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

        _ = client?.getTreatmentsByFlagSet(flagSet: "set2", attributes: nil)
        _ = client?.getTreatmentsByFlagSets(flagSets: ["set10", "set20"], attributes: nil)
        _ = client?.getTreatmentsWithConfigByFlagSet(flagSet: "set2", attributes: nil)
        _ = client?.getTreatmentsWithConfigByFlagSets(flagSets: ["set1", "set2"], attributes: nil)

        client?.flush()

        wait(for: [telemetryStatsExp!], timeout: 3)

        XCTAssertEqual("since=-1&sets=c,nset1,nset2,set1,set10,set2,set20", querystring)
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsByFlagSet ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsByFlagSets ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsWithConfigByFlagSet ?? [])
        XCTAssertEqual(expLatencies, telemetryStatsSent?.methodLatencies?.treatmentsWithConfigByFlagSets ?? [])

    }

    func testPolling() throws {
        loadSplitChangesFlagSetsJson()
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        pollingFlagSetsHits[0] = getChangeFlagSetsJson(since: 1, till: 1, 
                                                       sets1: ["set_1", "set_2"],
                                                       sets2: ["set_3"], sets3: [])!

        pollingFlagSetsHits[1] = getChangeFlagSetsJson(since: 1, till: 1,
                                                       sets1: ["set_1"],
                                                       sets2: ["set_3"], sets3: [])!

        pollingFlagSetsHits[3] = getChangeFlagSetsJson(since: 1, till: 1,
                                                       sets1: ["set_3"],
                                                       sets2: ["set_3"], sets3: [])!

        pollingExps = [XCTestExpectation(), XCTestExpectation(), XCTestExpectation()]

        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["set_1", "set_2"]))
            .build()

        telemetryStatsExp = XCTestExpectation()
        let client = try startTest(syncConfig: syncConfig)


//        Initialize a factory with polling and sets set_1 & set_2 configured.
//
//        Receive split change with 1 split belonging to set_1 & set_2 and one belonging to set_3  (splitChange2)
//        -> only one feature flag should be added
//
//        Receive split change with 1 split belonging to set_1 only  (splitChange1)
//        -> the feature flag should be updated
//
//        Receive split change with 1 split belonging to set_3 only  (splitChange0)
//        -> the feature flag should be removed


    }



    private func bodyTest(syncConfig: SyncConfig, telemetryEnabled: Bool = false) throws {
        let client = try startTest(syncConfig: syncConfig, telemetryEnabled: telemetryEnabled)
        destroyTest(client: client)
    }

    private func startTest(syncConfig: SyncConfig, telemetryEnabled: Bool = false) throws -> SplitClient?  {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.sdkReadyTimeOut = 6000
        splitConfig.logLevel = .verbose
        splitConfig.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: telemetryEnabled)
        splitConfig.internalTelemetryRefreshRate = 1

        splitConfig.sync = syncConfig

        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(testDb)
        _ = builder.setHttpClient(httpClient)
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 20)

        return client
    }

    private func destroyTest(client: SplitClient?) {
        let semaphore = DispatchSemaphore(value: 0)

        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        let change = loadSplitChangeFile(name: "splitchanges_1")
        change?.since = change?.till ?? -1
        return change
    }

    private func getChangeFlagSetsJson(since: Int64,
                                       till: Int64,
                                       sets1: [String],
                                       sets2: [String],
                                       sets3: [String]) -> Data? {

        let setField1 = "{{SPLIT_SETS_1}}"
        let setField2 = "{{SPLIT_SETS_2}}"
        let setField3 = "{{SPLIT_SETS_3}}"
        let sinceField = "{{SINCE}}"
        let tillField = "{{TILL}}"
        let sets1Json = toJsonArray(stringArray: sets1)
        let sets2Json = toJsonArray(stringArray: sets2)
        let sets3Json = toJsonArray(stringArray: sets3)

        return Data(
            changeFlagSetsJson.replacingOccurrences(of: setField1, with: sets1Json)
                .replacingOccurrences(of: setField2, with: sets2Json)
                .replacingOccurrences(of: setField3, with: sets3Json)
                .replacingOccurrences(of: sinceField, with: String(since))
                .replacingOccurrences(of: tillField, with: String(till))
                .utf8
        )
    }

    private func loadSplitChangesFlagSetsJson() {
        if let content = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_flagsets", type: "json") {
           changeFlagSetsJson = content
        }
    }

    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.decodeFrom(json: file, to: SplitChange.self) {
            return change
        }
        return nil
    }

    func toJsonArray(stringArray: [String]) -> String {
        return (try? JSONSerialization.data(withJSONObject: stringArray, options: .prettyPrinted))?.stringRepresentation ?? ""
    }
}

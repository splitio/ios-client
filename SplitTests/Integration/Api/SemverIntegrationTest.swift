//
//  SemverIntegrationTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import XCTest
@testable import Split

class SemverIntegrationTest: XCTestCase {

    let apiKey = IntegrationHelper.dummyApiKey
    let matchingKey = IntegrationHelper.dummyUserKey
    let trafficType = "user"
    let kNeverRefreshRate = 9999999
    var splitChange: SplitChange?
    var testDb: SplitDatabase!
    var httpClient: HttpClient!
    var factory: SplitFactory!
    var splitChangesHit = 0
    let mySegmentsJson = "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}"
    var streamingHelper: StreamingTestingHelper!
    var impressionsOnListener: [Impression] = []

    override func setUp() {
        Spec.flagsSpec = ""
        testDb = TestingHelper.createTestDatabase(name: "GralIntegrationTest")
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        impressionsOnListener = []
        streamingHelper = StreamingTestingHelper()
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }
    
    func testEqualToSemverMatcher() throws {
        let client = try? startTest()
        
        XCTAssertEqual("on", client?.getTreatment("semver_equalto", attributes: ["version": "1.22.9"]))
        XCTAssertEqual("off", client?.getTreatment("semver_equalto", attributes: ["version": "1.22.9+build"]))
        XCTAssertEqual("off", client?.getTreatment("semver_equalto", attributes: ["version": "1.22.9-rc.0"]))
        XCTAssertEqual("off", client?.getTreatment("semver_equalto", attributes: ["version": nil]))
        XCTAssertEqual("off", client?.getTreatment("semver_equalto"))

        assertImpressions(labelCount: 1, defaultLabelCount: 4, totalCount: 5, defaultLabel: "equal to semver")
    }

    func testInListSemverMatcher() throws {
        let client = try? startTest()

        XCTAssertEqual("on", client?.getTreatment("semver_inlist", attributes: ["version": "2.1.0"]))
        XCTAssertEqual("on", client?.getTreatment("semver_inlist", attributes: ["version": "1.22.9"]))
        XCTAssertEqual("off", client?.getTreatment("semver_inlist", attributes: ["version": "1.22.9+build"]))
        XCTAssertEqual("off", client?.getTreatment("semver_inlist", attributes: ["version": "1.22.9-rc.0"]))
        XCTAssertEqual("off", client?.getTreatment("semver_inlist", attributes: ["version": nil]))

        assertImpressions(labelCount: 2, defaultLabelCount: 3, totalCount: 5, defaultLabel: "in list semver")
    }

    func testGreaterThanOrEqualToSemverMatcher() throws {
        let client = try? startTest()

        XCTAssertEqual("on", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "1.23.9"]))
        XCTAssertEqual("on", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "1.22.9"]))
        XCTAssertEqual("on", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "1.22.9+build"]))
        XCTAssertEqual("off", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "1.22.9-rc.0"]))
        XCTAssertEqual("off", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "1.21.9"]))
        XCTAssertEqual("off", client?.getTreatment("semver_greater_or_equalto", attributes: ["version": "invalid"]))

        assertImpressions(labelCount: 3, defaultLabelCount: 3, totalCount: 6, defaultLabel: "greater than or equal to semver")
    }

    func testLessThanOrEqualToSemverMatcher() throws {
        let client = try? startTest()

        XCTAssertEqual("off", client?.getTreatment("semver_less_or_equalto", attributes: ["version": "1.22.11"]))
        XCTAssertEqual("on", client?.getTreatment("semver_less_or_equalto", attributes: ["version": "1.22.9"]))
        XCTAssertEqual("on", client?.getTreatment("semver_less_or_equalto", attributes: ["version": "1.22.9+build"]))
        XCTAssertEqual("on", client?.getTreatment("semver_less_or_equalto", attributes: ["version": "1.22.9-rc.0"]))
        XCTAssertEqual("on", client?.getTreatment("semver_less_or_equalto", attributes: ["version": "1.21.9"]))
        XCTAssertEqual("off", client?.getTreatment("semver_less_or_equalto", attributes: ["version": nil]))

        assertImpressions(labelCount: 4, defaultLabelCount: 2, totalCount: 6, defaultLabel: "less than or equal to semver")
    }

    func testBetweenSemverMatcher() throws {
        let client = try? startTest()

        XCTAssertEqual("off", client?.getTreatment("semver_between", attributes: ["version": "2.1.1"]))
        XCTAssertEqual("on", client?.getTreatment("semver_between", attributes: ["version": "2.1.0+build"]))
        XCTAssertEqual("on", client?.getTreatment("semver_between", attributes: ["version": "1.25.0"]))
        XCTAssertEqual("on", client?.getTreatment("semver_between", attributes: ["version": "1.25.9"]))
        XCTAssertEqual("off", client?.getTreatment("semver_between", attributes: ["version": "1.22.9-rc.0"]))
        XCTAssertEqual("off", client?.getTreatment("semver_between", attributes: ["version": []]))

        assertImpressions(labelCount: 3, defaultLabelCount: 3, totalCount: 6, defaultLabel: "between semver")
    }

    private func startTest() throws -> SplitClient?  {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.sdkReadyTimeOut = 6000
        splitConfig.logLevel = TestingHelper.testLogLevel
        splitConfig.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: false)
        splitConfig.internalTelemetryRefreshRate = 10000
        splitConfig.streamingEnabled = false
        splitConfig.impressionRefreshRate = 30
        splitConfig.featuresRefreshRate = kNeverRefreshRate
        splitConfig.impressionsMode = "debug"
        splitConfig.impressionsQueueSize = 100000
        splitConfig.impressionsChunkSize = 100000
        splitConfig.impressionListener = { impression in
            self.impressionsOnListener.append(impression)
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
        wait(for: expectations, timeout: 5)

        return client
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        let change = loadSplitChangeFile(name: "split_changes_semver")
        change?.since = change?.till ?? -1
        return change
    }

    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.decodeFrom(json: file, to: SplitChange.self) {
            return change
        }
        return nil
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                if self.splitChangesHit == 0 {
                    return TestDispatcherResponse(code: 200, data: try? Json.encodeToJsonData(self.loadSplitsChangeFile()))
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

            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingHelper.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingHelper.streamingBinding!
        }
    }

    private func assertImpressions(labelCount: Int, defaultLabelCount: Int, totalCount: Int, defaultLabel: String) {
        sleep(1)
        let impEntities = testDb.impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 100)

        XCTAssertEqual(labelCount, impEntities.filter { $0.label == defaultLabel }.count)
        XCTAssertEqual(defaultLabelCount, impEntities.filter { $0.label == "default rule" }.count)
        XCTAssertEqual(totalCount, impEntities.count)
        XCTAssertEqual(labelCount, impressionsOnListener.filter { $0.label == defaultLabel }.count)
        XCTAssertEqual(defaultLabelCount, impressionsOnListener.filter { $0.label == "default rule" }.count)
        XCTAssertEqual(totalCount, impressionsOnListener.count)
    }
}

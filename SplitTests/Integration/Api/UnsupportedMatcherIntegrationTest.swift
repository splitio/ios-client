//
//  UnsupportedMatcherIntegrationTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class UnsupportedMatcherIntegrationTest: XCTestCase {

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

    override func tearDown() {
        guard let client = factory?.client else { return }
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testFeatureFlagWithUnsupportedMatcherIsPresentInManager() {
        let factory = try? startTest()
        
        XCTAssertEqual(1, factory?.manager.splits.count ?? 0)
        XCTAssertEqual(1, factory?.manager.splitNames.count ?? 0)
    }

    func testGetTreatmentForUnsupportedMatcherFeatureFlagReturnsControl() {
        let factory = try? startTest()

        let treatment = factory?.client.getTreatment("feature_flag_for_test")

        XCTAssertEqual("control", treatment)
    }

    func testGetTreatmentWithConfigForUnsupportedMatcherFeatureFlagReturnsControl() {
        let factory = try? startTest()

        let treatment = factory?.client.getTreatmentWithConfig("feature_flag_for_test")

        XCTAssertEqual("control", treatment?.treatment)
    }

    func testStoredImpressionHasUnsupportedLabel() {
        let factory = try? startTest()

        _ = factory?.client.getTreatmentWithConfig("feature_flag_for_test")

        sleep(1)
        let storedImpressions = testDb.impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 100)

        XCTAssertEqual(1, storedImpressions.count)
        XCTAssertTrue(storedImpressions[0].label == "targeting rule type unsupported by sdk")
    }

    func testImpressionInListenerHasUnsupportedLabel() {
        let factory = try? startTest()

        _ = factory?.client.getTreatmentWithConfig("feature_flag_for_test")

        XCTAssertEqual("targeting rule type unsupported by sdk", impressionsOnListener[0].label)
    }

    private func startTest() throws -> SplitFactory?  {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.sdkReadyTimeOut = 6000
        splitConfig.logLevel = .warning//TestingHelper.testLogLevel
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

        return factory
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        let change = loadSplitChangeFile(name: "splitchanges_unsupported")
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
}

//
//  RuleBasedSegmentsIntegrationTest.swift
//  SplitTests
//
//  Created on 15/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

private let rbsChange0 = RuleBasedSegmentsIntegrationTest.rbsChange(changeNumber: "2", previousChangeNumber: "1", compressedPayload: "eyJuYW1lIjoicmJzX3Rlc3QiLCJzdGF0dXMiOiJBQ1RJVkUiLCJ0cmFmZmljVHlwZU5hbWUiOiJ1c2VyIiwiZXhjbHVkZWQiOnsia2V5cyI6W10sInNlZ21lbnRzIjpbXX0sImNvbmRpdGlvbnMiOlt7Im1hdGNoZXJHcm91cCI6eyJjb21iaW5lciI6IkFORCIsIm1hdGNoZXJzIjpbeyJrZXlTZWxlY3RvciI6eyJ0cmFmZmljVHlwZSI6InVzZXIifSwibWF0Y2hlclR5cGUiOiJBTExfS0VZUyIsIm5lZ2F0ZSI6ZmFsc2V9XX19XX0=")

private let rbsChangegzip = RuleBasedSegmentsIntegrationTest.rbsChangeGZip(
    changeNumber: "2",
    previousChangeNumber: "1",
    compressedPayload: "H4sIAAAAAAAA/0zOwWrDMBAE0H+Zs75At9CGUhpySSiUYoIij1MTSwraFdQY/XtRU5ccd3jDzoLoAmGRz3JSisJA1GkRWGyejq/vWxhodsMw+uN84/7OizDDgN9+Kj172AVXzgL72RkIL4FRf69q4FPsRx1TbMGC4NR/Mb/kVG6t51M4j5G5Pdw/w6zgrq+cD5zoNeWGH5asK+p/4y/d7Hant+3HAQaRF6eEHdwkrF2tXf0JAAD//9JucZnyAAAA"
)

private let rbsChangeZLib = RuleBasedSegmentsIntegrationTest.rbsChangeZlib(
    changeNumber: "2",
    previousChangeNumber: "1",
    compressedPayload: "eJxMzsFqwzAQBNB/mbO+QLfQhlIackkolGKCIo9TE0sK2hXUGP17UVOXHHd4w86C6AJhkc9yUorCQNRpEVhsno6v71sYaHbDMPrjfOP+zosww4Dffio9e9gFV84C+9kZCC+BUX+vauBT7EcdU2zBguDUfzG/5FRuredTOI+RuT3cP8Os4K6vnA+c6DXlhh+WrCvqf+Mv3ex2p7ftxwEGkRenhB3cJKxdrV39CQAA//8FrVMM"
)

class RuleBasedSegmentsIntegrationTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var sseExp = XCTestExpectation(description: "Sse conn")
    var authRequestUrl: String = ""
    var targetingRulesChange: String!
    var testDatabase: SplitDatabase?
    var useEmptySegments: Bool = true
    var trackedSplitChangeRequests: [HttpDataRequest] = []

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        useEmptySegments = true
        targetingRulesChange = nil
        authRequestUrl = ""
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        testDatabase = TestingHelper.createTestDatabase(name: "rbs_test_db")
    }

    func testInstantUpdateNotificationGZip() {
        let client = getReadyClient()
        XCTAssertNotNil(client)

        processUpdate(client: client!, change: rbsChangegzip, expectedContents: "rbs_test")
    }

    func testInstantUpdateNotification() {
        let client = getReadyClient()
        XCTAssertNotNil(client)
        
        processUpdate(client: client!, change: rbsChange0, expectedContents: "rbs_test")
    }

    func testInstantUpdateNotificationZlib() {
        let client = getReadyClient()
        XCTAssertNotNil(client)

        processUpdate(client: client!, change: rbsChangeZLib, expectedContents: "rbs_test")
    }

    func testEvaluation() {
        let splitChangesJson = IntegrationHelper.loadSplitChangeFileJson(name: "split_changes_rbs", sourceClass: IntegrationHelper())
        targetingRulesChange = splitChangesJson

        let client = getReadyClient()
        XCTAssertNotNil(client, "Client not ready")

        // Simulate streaming connection if needed
        streamingBinding?.push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002")

        // Evaluate treatment
        let attributes = ["email": "test@split.io"]
        let treatment = client!.getTreatment("rbs_split", attributes: attributes)
        XCTAssertEqual("on", treatment)
    }

    func testRbSinceParameterProgression() {
        // Clear any previous tracked requests
        trackedSplitChangeRequests.removeAll()

        // Set up custom response that will return some RBS data
        targetingRulesChange = RuleBasedSegmentsIntegrationTest.splitChangeWithReferencedRbs(flagSince: 1, rbsSince: 1)

        // Create first client - this should trigger initial sync with rbSince=-1
        let firstClient = getReadyClient()
        XCTAssertNotNil(firstClient, "First client not ready")

        // Wait for initial sync to complete
        sleep(2)

        // Create countdown latch for destroy completion
        let destroyExpectation = XCTestExpectation(description: "First client destroy completed")

        // Destroy the first client to clean up
        firstClient?.destroy {
            destroyExpectation.fulfill()
        }

        // Wait for destroy to complete
        wait(for: [destroyExpectation], timeout: 10)

        // Clear streaming binding and reset for second client
        streamingBinding = nil
        isSseHit = false
        isSseAuthHit = false

        // Reset SSE expectation for the second client
        sseExp = XCTestExpectation(description: "Sse conn")

        // Update the response to simulate changed data that would trigger another sync
        targetingRulesChange = RuleBasedSegmentsIntegrationTest.splitChangeWithReferencedRbs(flagSince: 2, rbsSince: 2)

        // Create second client - this should trigger sync with rbSince != -1 (using stored value)
        let secondClient = getReadyClient()
        XCTAssertNotNil(secondClient, "Second client not ready")

        // Wait for second sync to complete
        sleep(2)

        // Create countdown latch for second client destroy completion
        let secondDestroyExpectation = XCTestExpectation(description: "Second client destroy completed")

        // Clean up second client
        secondClient?.destroy {
            secondDestroyExpectation.fulfill()
        }

        // Wait for second destroy to complete
        wait(for: [secondDestroyExpectation], timeout: 10)

        // Extract rbSince values from the tracked requests
        let rbSinceValues = trackedSplitChangeRequests.compactMap { request -> String? in
            let url = request.url
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return nil
            }

            return queryItems.first { $0.name == "rbSince" }?.value
        }

        // Verify we have at least 2 requests
        XCTAssertGreaterThanOrEqual(rbSinceValues.count, 2, "Should have at least 2 splitChanges requests")

        // Verify first request uses rbSince=-1
        XCTAssertEqual(rbSinceValues.first, "-1", "First splitChanges request should use rbSince=-1")

        // Verify subsequent requests don't use -1
        if rbSinceValues.count > 1 {
            XCTAssertNotEqual(rbSinceValues[1], "-1", "Second splitChanges request should not use rbSince=-1")

            // Verify that the second request uses rbSince=1 (the value from the first response)
            XCTAssertEqual(rbSinceValues[1], "1", "Second splitChanges request should use rbSince=1 from previous response")
        }
    }

    func testReferencedRuleBasedSegmentNotPresentTriggersFetch() {
        let data = "eyJuYW1lIjoicmJzX3Rlc3QiLCJzdGF0dXMiOiJBQ1RJVkUiLCJ0cmFmZmljVHlwZU5hbWUiOiJ1c2VyIiwiZXhjbHVkZWQiOnsia2V5cyI6W10sInNlZ21lbnRzIjpbXX0sImNvbmRpdGlvbnMiOlt7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoidXNlciJ9LCJtYXRjaGVyVHlwZSI6IklOX1JVTEVfQkFTRURfU0VHTUVOVCIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjp7InNlZ21lbnROYW1lIjoibmV3X3Jic190ZXN0In19XX19XX0="
        targetingRulesChange = RuleBasedSegmentsIntegrationTest.splitChangeWithReferencedRbs(flagSince: 3, rbsSince: 3)
        referencedRbsTest(change: RuleBasedSegmentsIntegrationTest.rbsChangeInternal(changeNumber: "4", previousChangeNumber: "4", compressionType: "0", compressedPayload: data))
    }

    func testEvaluationWithExcludedSegment() {
        // Load split changes with rule-based segments
        let splitChangesJson = IntegrationHelper.loadSplitChangeFileJson(name: "split_changes_rbs", sourceClass: IntegrationHelper())
        targetingRulesChange = splitChangesJson
        useEmptySegments = false

        // Get a ready client
        let client = getReadyClient()
        XCTAssertNotNil(client, "Client not ready")

        // Test that a user in an excluded segment gets the "off" treatment
        let attributes: [String: Any] = ["email": "test@split.io"]
        let treatment = client!.getTreatment("rbs_split", attributes: attributes)
        XCTAssertEqual("off", treatment)
    }

    func testEvaluationWithExcludedKey() {
        let matchingKey = "key22"
        let excludedKey = Key(matchingKey: matchingKey)

        let splitChangesJson = IntegrationHelper.loadSplitChangeFileJson(name: "split_changes_rbs", sourceClass: IntegrationHelper())
        targetingRulesChange = splitChangesJson

        // Get a ready client with the excluded key
        let client = getReadyClient(key: excludedKey)
        XCTAssertNotNil(client, "Client not ready")

        // Test that the excluded key gets the "off" treatment
        let attributes: [String: Any] = ["email": "test@split.io"]
        let treatment = client!.getTreatment("rbs_split", attributes: attributes)
        XCTAssertEqual("off", treatment)
    }

    private func referencedRbsTest(change: String) {
        _ = getReadyClient()!
        sleep(2)
        streamingBinding?.push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok
        streamingBinding?.push(message: change)

        targetingRulesChange = RuleBasedSegmentsIntegrationTest.splitChangeWithReferencedRbs(flagSince: 5, rbsSince: 5)

        let allElements = testDatabase!.ruleBasedSegmentDao.getAll()

        XCTAssertEqual(2, allElements.count)
        let names = allElements.map { $0.name }
        XCTAssertEqual(1, names.filter { $0 == "rbs_test" }.count)
        XCTAssertEqual(1, names.filter { $0 == "new_rbs_test" }.count)
    }

    private func getReadyClient(key: Key? = nil) -> SplitClient? {

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.logLevel = .verbose

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(testDatabase!)
        let factory = builder.setApiKey(apiKey).setKey(key ?? Key(matchingKey: userKey))
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        var timeOutFired = false
        var sdkReadyFired = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertTrue(isSseAuthHit)
        XCTAssertTrue(isSseHit)

        return client
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                self.trackedSplitChangeRequests.append(request)

                if let change = self.targetingRulesChange {
                    return TestDispatcherResponse(code: 200, data: Data(change.utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 1, till: 1).utf8))
            }
            if request.isMySegmentsEndpoint() {
                if self.useEmptySegments {
                    return TestDispatcherResponse(code:200, data: Data(IntegrationHelper.emptyMySegments.utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.mySegments(names: ["segment_test"]).utf8))
            }
            if request.isAuthEndpoint() {
                let urlString = request.url.absoluteString
                self.authRequestUrl = urlString
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }

    static func rbsChange(changeNumber: String, previousChangeNumber: String, compressionType: String, compressedPayload: String) -> String {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        return """
        id: 123123
        event: message
        data: {\"id\":\"1111\",\"clientId\":\"pri:ODc1NjQyNzY1\",\"timestamp\":\(timestamp),\"encoding\":\"json\",\"channel\":\"xxxx_xxxx_flags\",\"data\":\"{\\\"type\\\":\\\"RB_SEGMENT_UPDATE\\\",\\\"changeNumber\\\":\(changeNumber),\\\"pcn\\\":\(previousChangeNumber),\\\"c\\\":\(compressionType),\\\"d\\\":\\\"\(compressedPayload)\\\"}\"}
        
        """
    }

    static func splitChangeWithReferencedRbs(flagSince: Int64, rbsSince: Int64) -> String {
        return """
        {"ff":{"s":\(flagSince),"t":\(flagSince),"d":[]},"rbs":{"s":\(rbsSince),"t":\(rbsSince),"d":[{"name":"new_rbs_test","status":"ACTIVE","trafficTypeName":"user","excluded":{"keys":[],"segments":[]},"conditions":[{"matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"WHITELIST","negate":false,"whitelistMatcherData":{"whitelist":["mdp","tandil","bsas"]}},{"keySelector":{"trafficType":"user","attribute":"email"},"matcherType":"ENDS_WITH","negate":false,"whitelistMatcherData":{"whitelist":["@split.io"]}}]}}]},{"name":"rbs_test","status":"ACTIVE","trafficTypeName":"user","excluded":{"keys":[],"segments":[]},"conditions":[{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"IN_RULE_BASED_SEGMENT","negate":false,"userDefinedSegmentMatcherData":{"segmentName":"new_rbs_test"}}]}}]}]}}
        """
    }

    static func rbsChange(changeNumber: String, previousChangeNumber: String, compressedPayload: String) -> String {
        return rbsChangeInternal(changeNumber: changeNumber, previousChangeNumber: previousChangeNumber, compressionType: "0", compressedPayload: compressedPayload)
    }

    static func rbsChangeGZip(changeNumber: String, previousChangeNumber: String, compressedPayload: String) -> String {
        return rbsChangeInternal(changeNumber: changeNumber, previousChangeNumber: previousChangeNumber, compressionType: "1", compressedPayload: compressedPayload)
    }

    static func rbsChangeZlib(changeNumber: String, previousChangeNumber: String, compressedPayload: String) -> String {
        return rbsChangeInternal(changeNumber: changeNumber, previousChangeNumber: previousChangeNumber, compressionType: "2", compressedPayload: compressedPayload)
    }

    static func rbsChangeInternal(changeNumber: String, previousChangeNumber: String, compressionType: String, compressedPayload: String) -> String {
        let timestamp = Date.now()
        return """
        id: 123123
        event: message
        data: {\"id\":\"1111\",\"clientId\":\"pri:ODc1NjQyNzY1\",\"timestamp\":\(timestamp),\"encoding\":\"json\",\"channel\":\"xxxx_xxxx_flags\",\"data\":\"{\\\"type\\\":\\\"RB_SEGMENT_UPDATE\\\",\\\"changeNumber\\\":\(changeNumber),\\\"pcn\\\":\(previousChangeNumber),\\\"c\\\":\(compressionType),\\\"d\\\":\\\"\(compressedPayload)\\\"}\"}\n\n"
    """
    }

    private func processUpdate(
        client: SplitClient,
        change: String,
        expectedContents: String
    ) {
        let sdkUpdateExpectation = XCTestExpectation(description: "SDK_UPDATE received")
        var sdkUpdatedTriggered = false

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedTriggered = true
            sdkUpdateExpectation.fulfill()
        }

        streamingBinding?.push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok
        streamingBinding?.push(message: change)
        wait(for: [sdkUpdateExpectation], timeout: 10)

        let containsExpectedContents = testDatabase!.ruleBasedSegmentDao.getAll().contains {
            $0.name == expectedContents
        }

        XCTAssertTrue(sdkUpdatedTriggered)
        XCTAssertTrue(containsExpectedContents)
    }

    static func loadSplitChangeFile(sourceClass: Any, fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: sourceClass, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change.featureFlags
        }
        return nil
    }
}

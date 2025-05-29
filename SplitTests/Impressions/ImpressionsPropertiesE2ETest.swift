//
//  ImpressionsPropertiesE2ETest.swift
//  SplitTests
//
//  Copyright 2025 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsPropertiesE2ETest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var firstSplitHit = true
    var sseExp: XCTestExpectation!
    var impExp: XCTestExpectation?
    var countExp: XCTestExpectation?
    var impressions: [String: [KeyImpression]]!
    var counts: [String: Int]!
    let queue = DispatchQueue(label: "queue", target: .test)
    var db: SplitDatabase!
    var requestBodies: [String] = []

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        impressions = [String: [KeyImpression]]()
        counts = [String: Int]()
        sseExp = XCTestExpectation(description: "Sse conn")
        impExp = nil
        requestBodies = []
    }

    func testImpressionsWithPropertiesAreNotDedupedInOptimizedMode() {
        runTest(mode: "OPTIMIZED", withProperties: true, expectDeduplication: false)
    }

    func testImpressionsWithoutPropertiesAreDedupedInOptimizedMode() {
        // Test that impressions without properties are deduped in OPTIMIZED mode
        runTest(mode: "OPTIMIZED", withProperties: false, expectDeduplication: true)
    }

    func testPropertiesAreIncludedInRequestBody() {
        let client = setupClient(mode: "OPTIMIZED")

        // Create test properties
        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        // Get treatment with properties
        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        impExp = XCTestExpectation()
        client.flush()

        wait(for: [impExp!], timeout: 10)

        // Verify properties in request body
        XCTAssertFalse(requestBodies.isEmpty, "Request bodies should not be empty")

        // Check if properties are included in the request body as a stringified JSON
        let containsProperties = requestBodies.contains { body in
            body.contains("\"properties\":")
        }
        XCTAssertTrue(containsProperties, "Request body should contain properties field")

        // Check if the properties are properly stringified
        let containsPropertiesValue = requestBodies.contains { body in
            print(body)
            return body.contains("\\\"test\\\":\\\"value\\\"") && body.contains("\\\"number\\\":123")
        }
        XCTAssertTrue(containsPropertiesValue, "Request body should contain the correct property values")

        cleanupClient(client)
    }

    func testNoImpressionsAreTrackedInNoneMode() {
        // Test that no impressions are tracked in NONE mode
        let client = setupClient(mode: "NONE")

        // Create test properties
        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        // Get treatment with properties
        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        // Get treatment without properties
        _ = client.getTreatment("test_string_without_attr")

        // Set up expectation to detect if impressions are sent
        impExp = XCTestExpectation()
        impExp?.isInverted = true // We expect this not to be fulfilled

        // Flush to trigger any potential impression sending
        client.flush()

        // Wait a short time to see if any impressions are sent
        wait(for: [impExp!], timeout: 1)

        // Verify no impressions were tracked
        XCTAssertEqual(0, requestBodies.count, "No impression requests should be made in NONE mode")

        cleanupClient(client)
    }

    func testPropertiesArePresentInImpressionListener() {
        // Create expectations for the impression listener
        let withPropertiesExpectation = XCTestExpectation(description: "Impression with properties")
        let withoutPropertiesExpectation = XCTestExpectation(description: "Impression without properties")

        // Track which feature flags we've seen in the listener
        var seenFeatureFlags = Set<String>()

        // Setup a client with an impression listener
        let client = setupClientWithImpressionListener { impression in
            // Determine which feature flag this is for
            guard let feature = impression.feature else {
                XCTFail("Feature name should not be nil")
                return
            }

            seenFeatureFlags.insert(feature)

            if feature == "FACUNDO_TEST" {
                withPropertiesExpectation.fulfill()

                XCTAssertNotNil(impression.properties, "Properties should not be nil for evaluation with properties")

                if let propertiesString = impression.properties {
                    XCTAssertTrue(propertiesString.contains("test"), "Properties should contain 'test' key")
                    XCTAssertTrue(propertiesString.contains("value"), "Properties should contain 'value'")
                    XCTAssertTrue(propertiesString.contains("number"), "Properties should contain 'number' key")
                    XCTAssertTrue(propertiesString.contains("123"), "Properties should contain '123'")
                }
            } else if feature == "test_string_without_attr" {
                withoutPropertiesExpectation.fulfill()

                XCTAssertNil(impression.properties, "Properties should be nil for evaluation without properties")
            }
        }

        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        _ = client.getTreatment("test_string_without_attr")

        wait(for: [withPropertiesExpectation, withoutPropertiesExpectation], timeout: 5)

        XCTAssertTrue(seenFeatureFlags.contains("FACUNDO_TEST"), "Should have seen impression for FACUNDO_TEST")
        XCTAssertTrue(
            seenFeatureFlags.contains("test_string_without_attr"),
            "Should have seen impression for test_string_without_attr")

        cleanupClient(client)
    }

    private func runTest(mode: String, withProperties: Bool, expectDeduplication: Bool) {
        let client = setupClient(mode: mode)

        let featureName = "FACUNDO_TEST"
        let evalOptions = withProperties ?
            EvaluationOptions(properties: ["test": "value"]) : nil

        let treatmentTimes = 5
        for _ in 0 ..< treatmentTimes {
            _ = client.getTreatment(featureName, attributes: nil, evaluationOptions: evalOptions)
        }

        impExp = XCTestExpectation()

        if expectDeduplication {
            countExp = XCTestExpectation()
        }

        client.flush()

        wait(for: [impExp!], timeout: 10)
        if expectDeduplication {
            wait(for: [countExp!], timeout: 10)
            sleep(1)
        }

        // Check the number of impressions recorded
        let expectedCount = 1
        XCTAssertEqual(
            expectedCount,
            impressions[featureName]?.count ?? 0,
            "Expected \(expectedCount) impressions for feature \(featureName)")

        if expectDeduplication {
            XCTAssertEqual(
                treatmentTimes - 1,
                counts[featureName] ?? 0,
                "Expected \(treatmentTimes - 1) impression count for feature \(featureName)")
        }

        cleanupClient(client)
    }

    private func setupClient(mode: String) -> SplitClient {
        let notificationHelper = NotificationHelperStub()
        db = TestingHelper.createTestDatabase(name: "test")

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = mode

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        return client
    }

    private func setupClientWithImpressionListener(_ listener: @escaping SplitImpressionListener) -> SplitClient {
        let notificationHelper = NotificationHelperStub()
        db = TestingHelper.createTestDatabase(name: "test")

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = "OPTIMIZED"
        splitConfig.impressionListener = listener

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        return client
    }

    private func createSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 999999
        splitConfig.eventsQueueSize = 99999
        splitConfig.eventsPushRate = 99999
        splitConfig.logLevel = .verbose
        splitConfig.impressionsQueueSize = 1
        splitConfig.impressionsChunkSize = 1
        return splitConfig
    }

    private func cleanupClient(_ client: SplitClient) {
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.firstSplitHit {
                    self.firstSplitHit = false
                    return TestDispatcherResponse(code: 200, data: Data(self.loadSplitsChangeFile().utf8))
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.queue.sync {
                    if let exp = self.impExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation.utf8 {
                        let bodyString = String(body)
                        self.requestBodies.append(bodyString)

                        if let tests = try? Json.decodeFrom(json: bodyString, to: [ImpressionsTest].self) {
                            for test in tests {
                                var imps = [KeyImpression]()
                                if let prevImp = self.impressions[test.testName] {
                                    imps.append(contentsOf: prevImp)
                                }
                                imps.append(contentsOf: test.keyImpressions)
                                self.impressions.updateValue(imps, forKey: test.testName)
                            }
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isImpressionsCountEndpoint() {
                self.queue.sync {
                    if let exp = self.countExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation.utf8 {
                        if let impressionsCount = try? Json.decodeFrom(json: String(body), to: ImpressionsCount.self) {
                            for countPerFeature in impressionsCount.perFeature {
                                self.counts[countPerFeature.feature] = countPerFeature
                                    .count + (self.counts[countPerFeature.feature] ?? 0)
                            }
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            return TestDispatcherResponse(code: 200)
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

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json")
        else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }
}

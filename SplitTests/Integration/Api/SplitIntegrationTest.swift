//
//  SplitIntegrationTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitIntegrationTests: XCTestCase {

    let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
    let dataFolderName = "2a1099049fd8653247c5ea42bOIajMRhH0R0FcBwJZM4ca7zj6HAq1ZDS"
    let matchingKey = "CUSTOMER_ID"
    let trafficType = "account"
    let kNeverRefreshRate = 9999999
    var splitChange: SplitChange?
    var serverUrl = "localhost"
    var trackReqIndex = 0
    var impHit = [[ImpressionsTest]]()

    let mySegmentsJson = "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}"

    var trExp = [XCTestExpectation]()

    var streamingBinding: TestStreamResponseBinding?

    var httpClient: HttpClient!

    var trackRequestsData: [String] = []

    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        for i in 0 ... 9 {
            trExp.append(XCTestExpectation(description: "track: \(i)"))
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
                return TestDispatcherResponse(code: 200, data: try? Json.encodeToJsonData(self.splitChange))

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(self.mySegmentsJson.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("testImpressions/bulk"):

                self.impHit.append(try! TestUtils.impressionsFromHit(request: request))
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("events/bulk"):
                let index = self.getAndUpdateReqIndex()
                self.trackRequestsData.append(request.body!.stringRepresentation)
                if index < self.trExp.count {
                    self.trExp[index].fulfill()
                }
                return TestDispatcherResponse(code: 200)

            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    func testControlTreatment() throws {
        var impressions = [String:Impression]()

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 999999
        splitConfig.eventsFirstPushWindow = 999
        splitConfig.logLevel = TestingHelper.testLogLevel
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        splitConfig.impressionListener = { impression in
            impressions[IntegrationHelper.buildImpressionKey(impression: impression)] = impression
        }

        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "GralIntegrationTest"))
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client
        let manager = factory?.manager

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        var timeOutFired = false
        var sdkReadyFired = false

        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReadyExpectation.fulfill()
        }

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 20)

        let t1 = client?.getTreatment("FACUNDO_TEST")
        let t2 = client?.getTreatment("NO_EXISTING_FEATURE")
        let treatmentConfigEmojis = client?.getTreatmentWithConfig("Welcome_Page_UI")

        let ts1 = client?.getTreatments(splits: ["testing222", "NO_EXISTING_FEATURE1", "NO_EXISTING_FEATURE2"], attributes: nil)
        let s1 = manager?.split(featureName: "FACUNDO_TEST")
        let s2 = manager?.split(featureName: "NO_EXISTING_FEATURE")
        let splits = manager?.splits

        let i1 = impressions[IntegrationHelper.buildImpressionKey(key: "CUSTOMER_ID", splitName: "FACUNDO_TEST", treatment: "off")]
        let i2 = impressions[IntegrationHelper.buildImpressionKey(key: "CUSTOMER_ID", splitName: "NO_EXISTING_FEATURE", treatment: SplitConstants.control)]
        let i3 = impressions[IntegrationHelper.buildImpressionKey(key: "CUSTOMER_ID", splitName: "testing222", treatment: "off")]

        for i in 0..<101 {
            _ = client?.track(eventType: "account", value: Double(i))
        }

        wait(for: trExp, timeout: 30)

        let event1 = IntegrationHelper.getTrackEventBy(value: 1.0, trackHits: trackRequestsData)
        let event100 = IntegrationHelper.getTrackEventBy(value: 100.0, trackHits: trackRequestsData)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual("off", t1)
        XCTAssertEqual(SplitConstants.control, t2)
        XCTAssertEqual("{\"the_emojis\":\"\\uD83D\\uDE01 -- áéíóúöÖüÜÏëç\"}", treatmentConfigEmojis?.config)
        XCTAssertEqual("off", ts1?["testing222"])
        XCTAssertEqual(SplitConstants.control, ts1?["NO_EXISTING_FEATURE1"])
        XCTAssertEqual(SplitConstants.control, ts1?["NO_EXISTING_FEATURE2"])

        XCTAssertEqual(33, splits?.count)
        XCTAssertNotNil(s1)
        XCTAssertNil(s2)
        XCTAssertNotNil(i1)
        XCTAssertEqual(1506703262916, i1?.changeNumber)
        XCTAssertNil(i2)
        XCTAssertNotNil(i3)
        XCTAssertEqual(1505162627437, i3?.changeNumber)
        XCTAssertEqual("not in split", i1?.label) // TODO: Uncomment when impressions split name is added to impression listener
        XCTAssertEqual(10, trackRequestsData.count)
        XCTAssertNotNil(event1)
        XCTAssertNil(event100)
        XCTAssertEqual(3, impressions.count)

        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    func testImpressionsCount() throws {

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 999999
        splitConfig.segmentsRefreshRate = 999999
        splitConfig.impressionRefreshRate = 2
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 999999
        splitConfig.eventsQueueSize = 999999
        splitConfig.eventsPushRate = 999999
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "IntegrationTest"))
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 40)

        for _ in 0..<2 {
            _ = client?.getTreatment("FACUNDO_TEST")
            _ = client?.getTreatmentWithConfig("Welcome_Page_UI")
            _ = client?.getTreatments(splits: ["testing222", "NO_EXISTING_FEATURE1", "NO_EXISTING_FEATURE2"], attributes: nil)
            sleep(2)
        }

        sleep(8)
        let impCount = impHit.reduce(0, {  $0 + $1.count })
        XCTAssertEqual(6, impCount)

        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    func testReadyNoRef() throws {

        let splitConfig: SplitClientConfig = SplitClientConfig()

        splitConfig.impressionRefreshRate = 2
        splitConfig.sdkReadyTimeOut = 5000
        splitConfig.trafficType = trafficType

        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "IntegrationTest"))
        _ = builder.setHttpClient(httpClient)
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client

        var readyFired = false

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client?.on(event: SplitEvent.sdkReady) {
            readyFired = true
            sdkReadyExpectation.fulfill()
        }

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 10)

        XCTAssertTrue(readyFired)
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        let change = loadSplitChangeFile(name: "splitchanges_1")
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

    private func getAndUpdateReqIndex() -> Int {
        var i = 0
        DispatchQueue.test.sync {
            i = trackReqIndex
            trackReqIndex+=1
        }
        return i
    }
}

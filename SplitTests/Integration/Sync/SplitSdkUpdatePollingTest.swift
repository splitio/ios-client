//
//  SplitSdkUpdatePollingTest.swift
//  SplitSdkUpdatePollingTest
//
//  Created by Javier L. Avrudsky on 22/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitSdkUpdatePollingTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var streamingBinding: TestStreamResponseBinding?
    var httpClient: HttpClient!
    let kChangeNbInterval: Int64 = 86400
    var reqChangesIndex = 0
    var serverUrl = "https://split.test.ing"
    let kMatchingKey = IntegrationHelper.dummyUserKey
    var factory: SplitFactory?
    var mySegmentsHits = 0

    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    
    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    
    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        let respData = responseSlitChanges()
        var responses = [TestDispatcherResponse]()
        for data in respData {
            responses.append(TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(data).utf8)))
        }

        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let index = self.getAndIncrement()
                if index < self.spExp.count {
                    if index > 0 {
                        self.spExp[index - 1].fulfill()
                    }
                    return responses[index]
                } else if index == self.spExp.count {
                    self.spExp[index - 1].fulfill()
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 99999999, till: 99999999).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                self.mySegmentsHits+=1
                let hit = self.mySegmentsHits
                var json = IntegrationHelper.emptyMySegments
                if hit > 2 {
                    var mySegments = [Segment]()
                    for i in 1...hit {
                        mySegments.append(Segment(id: "\(i)", name: "segment\(i)"))
                    }

                    if let segments = try? Json.encodeToJson(mySegments) {
                        json = "{\"mySegments\": \(segments)}"
                    }
                    return TestDispatcherResponse(code: 200, data: Data(json.utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("testImpressions/bulk"):
                self.impHit = try? TestUtils.impressionsFromHit(request: request)
                self.impExp.fulfill()
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
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    // MARK: Test
    func testSdkReadyOnly() throws {
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.featuresRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        var sdkUpdatedFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedFired = true
        }
        
        wait(for: [sdkReady], timeout: 30)

        // wait for sdk update
        ThreadUtils.delay(seconds: 1.0)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(sdkUpdatedFired)


        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSdkUpdateSplits() throws {
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdate = XCTestExpectation(description: "SDK Update Expectation")

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.featuresRefreshRate = 2
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory!.client

        var sdkReadyFired = false
        var sdkUpdatedFired = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedFired = true
            sdkUpdate.fulfill()
        }

        wait(for: [sdkReady, sdkUpdate], timeout: 30)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertTrue(sdkUpdatedFired)


        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSdkUpdateMySegments() throws {
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdate = XCTestExpectation(description: "SDK Update Expectation")

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 2
        splitConfig.featuresRefreshRate = 999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory!.client

        var sdkReadyFired = false
        var sdkUpdatedFired = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedFired = true
            sdkUpdate.fulfill()
        }

        wait(for: [sdkReady, sdkUpdate], timeout: 30)

        // wait for sdk update
        ThreadUtils.delay(seconds: 1.0)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertTrue(sdkUpdatedFired)


        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func  responseSlitChanges() -> [SplitChange] {
        var changes = [SplitChange]()

        var prevChangeNumber: Int64 = 0
        for i in 0..<4 {
            let c = loadSplitsChangeFile()!
            c.since = c.till
            if prevChangeNumber != 0 {
                c.till = prevChangeNumber  + kChangeNbInterval
                c.since = c.till
            }
            prevChangeNumber = c.till
            let split = c.splits[0]
            let even = ((i + 2) % 2 == 0)
            split.changeNumber = prevChangeNumber
            split.conditions![0].partitions![0].treatment = "on_\(i)"
            split.conditions![0].partitions![0].size = (even ? 100 : 0)
            split.conditions![0].partitions![1].treatment = "off_\(i)"
            split.conditions![0].partitions![1].size = (even ? 0 : 100)
            changes.append(c)
        }
        return changes
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        return FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_int_test")
    }

    private func getAndIncrement() -> Int {
        var i = 0;
        DispatchQueue.test.sync {
            i = self.reqChangesIndex
            self.reqChangesIndex+=1
        }
        return i
    }
}


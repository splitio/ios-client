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
    var webServer: MockWebServer!
    let kChangeNbInterval: Int64 = 86400
    var reqChangesIndex = 0
    var serverUrl = ""
    let kMatchingKey = IntegrationHelper.dummyUserKey
    var factory: SplitFactory?

    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    
    override func setUp() {
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {

        webServer = MockWebServer()
        let respData = responseSlitChanges()
        var responses = [MockedResponse]()
        for data in respData {
            responses.append(MockedResponse(code: 200, data: try? Json.encodeToJson(data)))
        }

        webServer.routeGet(path: "/mySegments/:user_id",
                           data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, "
                            + "{ \"id\":\"id1\", \"name\":\"segment2\"}]}")

        webServer.route(method: .get, path: "/splitChanges") { request in
            let index = self.getAndIncrement()
            if index < self.spExp.count {
                if index > 0 {
                    self.spExp[index - 1].fulfill()
                }
                return responses[index]
            } else if index == self.spExp.count {
                self.spExp[index - 1].fulfill()
            }
            return MockedResponse(code: 200, data: "{\"splits\":[], \"since\": 9999999999999, \"till\": 9999999999999 }")
        }

        webServer.route(method: .post, path: "/testImpressions/bulk") { request in
            self.impHit = try? TestUtils.impressionsFromHit(request: request)
            self.impExp.fulfill()
            return MockedResponse(code: 200, data: nil)
        }
        webServer.start()
        serverUrl = webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }

    // MARK: Test
    func testSdkReadyOnly() throws {
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.featuresRefreshRate = 99999999999
        splitConfig.impressionRefreshRate = 9999999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
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
        splitConfig.impressionRefreshRate = 9999999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
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

    func testSdkUpdateMySegments() throws {
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdate = XCTestExpectation(description: "SDK Update Expectation")

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 2
        splitConfig.featuresRefreshRate = 999999999
        splitConfig.impressionRefreshRate = 9999999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
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

    private func impressionsHits() -> [ClientRequest] {
        return webServer.receivedRequests.filter { $0.path == "/testImpressions/bulk"}
    }

    private func getAndIncrement() -> Int {
        var i = 0;
        DispatchQueue.global().sync {
            i = self.reqChangesIndex
            self.reqChangesIndex+=1
        }
        return i
    }
}


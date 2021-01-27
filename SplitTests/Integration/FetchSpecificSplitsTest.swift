//
//  FetchSpecificSplitsTest.swift
//  FetchSpecificSplitsTest
//
//  Created by Javier L. Avrudsky on 05/08/2019.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class FetchSpecificSplitsTest: XCTestCase {

    let apiKey = IntegrationHelper.dummyApiKey
    let matchingKey = IntegrationHelper.dummyUserKey
    let trafficType = "account"
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    var splitChange: SplitChange?
    var serverUrl = ""
    var splitsRequestUrl = ""
    var lastChangeNumber = 0
    
    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {
        webServer = MockWebServer()
        webServer.routeGet(path: "/mySegments/:user_id", data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}")
        webServer.route(method: .get, path: "/splitChanges?since=:param") { request in
            self.splitsRequestUrl = "\(self.serverUrl)\(request.path)\(request.queryString ?? "")"
            let since = self.lastChangeNumber
            return MockedResponse(code: 200, data: IntegrationHelper.emptySplitChanges(since: since, till: since))
        }
        webServer.route(method: .post, path: "/testImpressions/bulk") { request in
            return MockedResponse(code: 200, data: nil)
        }
        webServer.route(method: .post, path: "/events/bulk") { request in
            return MockedResponse(code: 200)
        }
        webServer.start()
        serverUrl = webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }

    func testBothFilters() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byName(["s1", "s2", "s3"]))
        .addSplitFilter(SplitFilter.byPrefix(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?since=-1&names=s1,s2,s3&prefixes=s1,s2,s3")
    }

    func testByNamesFilter() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byName(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?since=-1&names=s1,s2,s3")
    }

    func testByPrefixFilter() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byPrefix(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?since=-1&prefixes=s1,s2,s3")
    }


    func urlQueryStringTest(syncConfig: SyncConfig, expectedResult: String) {
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        splitConfig.sync = syncConfig
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        builder.setTestDatabase(TestingHelper.createTestDatabase(name: "FetchSpecificSplit"))
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory?.client
        
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        var sdkReadyFired = false
        
        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReadyExpectation.fulfill()
        }
        
        wait(for: [sdkReadyExpectation], timeout: 40)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertEqual("\(serverUrl)\(expectedResult)", splitsRequestUrl)


        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }
    
    private func loadSplitsChangeFile() -> SplitChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }
    
    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self) {
            self.lastChangeNumber = Int(change.till)
            return change
        }
        return nil
    }
}


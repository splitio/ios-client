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
    var httpClient: HttpClient!
    var streamingBinding: TestStreamResponseBinding?

    var splitChange: SplitChange?
    var serverUrl = "localhost"
    var splitsRequestUrl = "localhost"
    var lastChangeNumber = 0
    
    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testBothFilters() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byName(["s1", "s2", "s3"]))
        .addSplitFilter(SplitFilter.byPrefix(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?s=1.1&since=-1&names=s1,s2,s3&prefixes=s1,s2,s3")
    }

    func testByNamesFilter() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byName(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?s=1.1&since=-1&names=s1,s2,s3")
    }

    func testByPrefixFilter() {
        let syncConfig = SyncConfig.builder()
        .addSplitFilter(SplitFilter.byPrefix(["s1", "s2", "s3"]))
        .build()
        urlQueryStringTest(syncConfig: syncConfig, expectedResult: "/splitChanges?s=1.1&since=-1&prefixes=s1,s2,s3")
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
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "FetchSpecificSplit"))
        _ = builder.setHttpClient(httpClient)
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
            let change = try? Json.decodeFrom(json: file, to: SplitChange.self) {
            self.lastChangeNumber = Int(change.till)
            return change
        }
        return nil
    }


    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):

                //self.splitsRequestUrl = String(request.url.absoluteString.suffix(request.url.absoluteString.count - 17))
                self.splitsRequestUrl = String(request.url.absoluteString)
                let since = self.lastChangeNumber
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: since, till: since).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

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
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}


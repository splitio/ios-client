//
//  OutdatedProxyIntegrationTest.swift
//  SplitTests
//
//  Created on 19/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class OutdatedProxyIntegrationTest: XCTestCase {
    
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var outdatedProxy = false
    var simulatedProxyError = false
    var recoveryHit = false
    var testDatabase: SplitDatabase!
    let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
    
    override func setUp() {
        super.setUp()
        outdatedProxy = false
        simulatedProxyError = false
        recoveryHit = false
        
        // Create test database
        testDatabase = TestingHelper.createTestDatabase(name: "outdated_proxy_test")
        
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }
    
    func testClientIsReadyEvenWhenUsingOutdatedProxy() {
        outdatedProxy = true
        let client = getReadyClient()
        
        XCTAssertNotNil(client)
        XCTAssertFalse(recoveryHit)
        XCTAssertTrue(simulatedProxyError)
    }
    
    func testClientIsReadyWithLatestProxy() {
        outdatedProxy = false
        let client = getReadyClient()
        
        XCTAssertNotNil(client)
        XCTAssertFalse(recoveryHit && outdatedProxy)
        XCTAssertFalse(simulatedProxyError)
    }
    
    func testClientRecoversFromOutdatedProxy() {
        outdatedProxy = false
        
        // Set last proxy check timestamp to 62 minutes ago
        let generalInfoDao = testDatabase.generalInfoDao
        generalInfoDao.update(info: GeneralInfo.lastProxyUpdateTimestamp, longValue: (Date.nowMillis() - 62 * 60 * 1000))
        
        let client = getReadyClient()
        
        XCTAssertNotNil(client)
        XCTAssertTrue(recoveryHit && !outdatedProxy)
        XCTAssertFalse(simulatedProxyError)
    }
    
    // MARK: - Helper Methods
    
    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            // We don't expect this to be called since streaming is disabled
            XCTFail("Streaming should be disabled")
            return TestStreamResponseBinding.createFor(request: request, code: 200)
        }
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                // Extract spec version from URI
                let specFromUri = self.getSpecFromUri(request.url)
                
                if self.outdatedProxy && specFromUri > 1.2 {
                    self.simulatedProxyError = true
                    return TestDispatcherResponse(code: 400, data: Data())
                } else if self.outdatedProxy {
                    let since = self.getSinceFromUri(request.url)
                    let body = (since == "-1") ?
                        IntegrationHelper.emptySplitChanges(since: 1506703262916, till: 1506703262916) :
                        IntegrationHelper.emptySplitChanges(since: -1, till: 1506703262916)
                    
                    return TestDispatcherResponse(code: 200, data: Data(body.utf8))
                }
                
                if !self.outdatedProxy {
                    if request.url.absoluteString.contains("?s=1.3&since=-1&rbSince=-1") {
                        self.recoveryHit = true
                    }
                }
                
                // Return a default split changes response
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 1, till: 1).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }
    
    private func getSpecFromUri(_ url: URL) -> Float {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems,
           let specItem = queryItems.first(where: { $0.name == "s" }),
           let specValue = specItem.value,
           let specFloat = Float(specValue) {
            return specFloat
        }
        return 1.0
    }
    
    private func getSinceFromUri(_ url: URL) -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems,
           let sinceItem = queryItems.first(where: { $0.name == "since" }),
           let sinceValue = sinceItem.value {
            return sinceValue
        }
        return "-1"
    }
    
    private func getReadyClient() -> SplitClient? {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 10000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.serviceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: "https://testing.split.io").build()
        splitConfig.logLevel = .verbose
        // Explicitly disable streaming
        splitConfig.streamingEnabled = false
        
        // Set flags spec to 1.3
        Spec.flagsSpec = "1.3"
        
        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(testDatabase)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!
        
        let client = factory.client
        
        var sdkReadyFired = false
        var timeOutFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            self.sdkReadyExp.fulfill()
        }
        
        client.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            self.sdkReadyExp.fulfill()
        }
        
        wait(for: [sdkReadyExp], timeout: 10)
        
        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        
        return client
    }
}


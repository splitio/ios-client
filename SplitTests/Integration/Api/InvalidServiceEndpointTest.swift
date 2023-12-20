//
//  InvalidServiceEndpointTest.swift
//  SplitTests
//
//  Created by Gaston Thea on 20/12/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import XCTest
@testable import Split

final class InvalidServiceEndpointTest: XCTestCase {

    let kNeverRefreshRate = 9999999

    var trackHitCounter = 0
    var impressionsHitCount = 0
    var splitChangesHitCount = 0
    var mySegmentsHitCount = 0
    var serverUrl = ""
    var lastChangeNumber = 1

    var impressions: [KeyImpression]!
    var events: [EventDTO]!
    var httpClient: HttpClient!
    var streamingBinding: TestStreamResponseBinding?

    override func setUpWithError() throws {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }
    
    
    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                self.splitChangesHitCount+=1
                let since = self.lastChangeNumber
                return TestDispatcherResponse(code: 200,
                                      data: Data(IntegrationHelper.emptySplitChanges(since: since, till: since).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                self.mySegmentsHitCount+=1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("testImpressions/bulk"):
                self.impressionsHitCount+=1
                if let data = request.body {
                    if let tests = try? IntegrationHelper.buildImpressionsFromJson(content: data.stringRepresentation) {
                        for test in tests {
                            self.impressions.append(contentsOf: test.keyImpressions)
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("events/bulk"):
                self.trackHitCounter+=1
                if let data = request.body {
                    if let e = try? IntegrationHelper.buildEventsFromJson(content: data.stringRepresentation) {
                        self.events.append(contentsOf: e)
                    }
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

    func testInvalidSdkServiceEndpointResultsInTimeout() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_h"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        let eventType = "testEvent"

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 5
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = 5
        splitConfig.impressionsChunkSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.sdkReadyTimeOut = 5
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 100
        splitConfig.eventsQueueSize = 1000
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "GralIntegrationTest"))
        _ = builder.setHttpClient(httpClient)
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory?.client

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

        wait(for: [sdkReadyExpectation], timeout: 10)

        XCTAssertFalse(sdkReadyFired)
        XCTAssertTrue(timeOutFired)
        XCTAssertTrue(splitChangesHitCount == 0)
        XCTAssertTrue(mySegmentsHitCount == 0)
    }
}

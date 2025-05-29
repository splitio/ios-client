//
//  StreamingAuthFail5xxTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

//
//  StreamingConnFail5xx.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingAuthFail5xxTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuth = false
    var isSseConnected = false
    var streamingBinding: TestStreamResponseBinding?
    let sseConnExp = XCTestExpectation(description: "Sse auth")
    let kMaxSseAuthRetries = 3
    var sseAuthHits = 0
    var sseConnHits = 0

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testInit() {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 999999
        splitConfig.segmentsRefreshRate = 999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
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

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: 20)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual(3, sseAuthHits)
        XCTAssertEqual(1, sseConnHits)
        XCTAssertTrue(isSseAuth)
        XCTAssertTrue(isSseConnected)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                self.sseAuthHits += 1
                if self.sseAuthHits < self.kMaxSseAuthRetries {
                    return TestDispatcherResponse(code: 500)
                }
                let resp = TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
                self.isSseAuth = true
                return resp
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseConnHits += 1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.isSseConnected = true
            self.sseConnExp.fulfill()
            return self.streamingBinding!
        }
    }
}

//
// StreamingInitTest.swift
// Split
//
// Created by Javier L. Avrudsky on 14-Oct-2020.
// Copyright (c) 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingNoReconectWhenPollingTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    var authHitCount = 0

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testShouldReconnect() {
        reconnectTest(streamingEnabled: true)
    }

    func testShouldNoReconnect() {
        reconnectTest(streamingEnabled: false)
    }

    func reconnectTest(streamingEnabled: Bool) {
        // Test intended to avoid the issue
        // of the SDK connecting to streaming when comming from BG
        // when streamingEnabled = false
        let notificationHelper = NotificationHelperStub()

        authHitCount = 0

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 99999
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 99999
        splitConfig.streamingEnabled = streamingEnabled

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        _ = builder.setNotificationHelper(notificationHelper)

        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 20)

        ThreadUtils.delay(seconds: 0.5)

        notificationHelper.simulateApplicationDidEnterBackground()

        ThreadUtils.delay(seconds: 0.3)

        notificationHelper.simulateApplicationDidBecomeActive()

        ThreadUtils.delay(seconds: 0.5)

        XCTAssertTrue((authHitCount > 0) == streamingEnabled)

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
                self.authHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}

//
// StreamingBgReconnectTest.swift
// Split
//
// Created by Javier L. Avrudsky on 17-Sep-2022.
// Copyright (c) 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingBgReconnectTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var streamingBinding: TestStreamResponseBinding?
    var sseExp: [XCTestExpectation]!

    var sseHitCount = 0

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testReconnect() {
        sseExp = [XCTestExpectation(description: "Sse conn1"), XCTestExpectation(description: "Sse conn2")]
        let notificationHelper = NotificationHelperStub()
        let splitConfig = SplitClientConfig()
        splitConfig.streamingEnabled = true

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

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp[0]], timeout: 10)

        notificationHelper.simulateApplicationDidEnterBackground()
        notificationHelper.simulateApplicationDidBecomeActive()

        #if !os(macOS)
            // It should disconnect and reconnect
            wait(for: [sseExp[1]], timeout: 20)

            XCTAssertEqual(sseHitCount, 2)
        #else
            // It shouldn't pause app
            ThreadUtils.delay(seconds: 2)

            XCTAssertEqual(sseHitCount, 1)
        #endif

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
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            let index = self.sseHitCount
            self.sseHitCount += 1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp[index].fulfill()
            return self.streamingBinding!
        }
    }
}

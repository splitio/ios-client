//
//  StreamingControlTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingControlResetTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var sseAuthHitCount = 0
    var sseHitCount = 0
    var streamingBinding: TestStreamResponseBinding?
    var sseExp = XCTestExpectation(description: "Sse conn")
    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"

    let kRefreshRate = 1

    var testFactory: TestSplitFactory!

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testStreamingReset() throws {
        let config = TestingHelper.basicStreamingConfig()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(config).build()!

        let client = factory.client

        var timestamp = 1000

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 5)

        streamingBinding?.push(message: ":keepalive")

        // Should auth and reconnect streaming
        sseExp = XCTestExpectation()
        timestamp += 1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(
            timestamp: timestamp,
            controlType: "STREAMING_RESET"))

        wait(for: [sseExp], timeout: 5)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(2, sseAuthHitCount)
        XCTAssertEqual(2, sseHitCount)

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
                self.sseAuthHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseHitCount += 1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }
}

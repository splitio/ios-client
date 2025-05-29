//
//  StreamingControlTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingDelaytTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var sseAuthHitCount = 0
    var sseHitCount = 0
    var streamingBinding: TestStreamResponseBinding?
    var sseExp = XCTestExpectation(description: "Sse conn")
    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"
    var sseConDelay = 0

    let kRefreshRate = 1

    var testFactory: TestSplitFactory!

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testStreamingDelay() throws {
        sseConDelay = 4
        let config = TestingHelper.basicStreamingConfig()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(config).build()!

        let client = factory.client

        var time = Date().unixTimestamp()

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 10)

        time = Date().unixTimestamp() - time

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertTrue(time > 3)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testNoStreamingDelay() throws {
        sseConDelay = 0
        let config = TestingHelper.basicStreamingConfig()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(config).build()!

        let client = factory.client

        var time = Date().unixTimestamp()

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 10)

        time = Date().unixTimestamp() - time

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertTrue(time < 2)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    #if !os(macOS)
        func testDelayOnReconnect() throws {
            sseConDelay = 4
            let config = TestingHelper.basicStreamingConfig()
            let notificationHelper = NotificationHelperStub()

            let key = Key(matchingKey: userKey)
            let builder = DefaultSplitFactoryBuilder()
            _ = builder.setHttpClient(httpClient)
            _ = builder.setReachabilityChecker(ReachabilityMock())
            _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
            _ = builder.setNotificationHelper(notificationHelper)
            let factory = builder.setApiKey(apiKey).setKey(key)
                .setConfig(config).build()!

            let client = factory.client

            var time = Date().unixTimestamp()

            let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

            client.on(event: SplitEvent.sdkReady) {
                sdkReadyExpectation.fulfill()
            }

            wait(for: [sdkReadyExpectation, sseExp], timeout: 10)
            time = Date().unixTimestamp() - time

            notificationHelper.simulateApplicationDidEnterBackground()
            ThreadUtils.delay(seconds: 1)

            sseExp = XCTestExpectation()
            var time1 = Date().unixTimestamp()
            notificationHelper.simulateApplicationDidBecomeActive()

            wait(for: [sseExp], timeout: 10)
            time1 = Date().unixTimestamp() - time1

            // Hits are not asserted because tests will fail if expectations are not fulfilled
            XCTAssertTrue(time > 3)
            print("TIME 1: \(time1)")
            XCTAssertTrue(time1 > 3)

            let semaphore = DispatchSemaphore(value: 0)
            client.destroy(completion: {
                _ = semaphore.signal()
            })
            semaphore.wait()
        }

        func testDelayOnReconnectStress() throws {
            sseConDelay = 2
            let config = TestingHelper.basicStreamingConfig()
            let notificationHelper = NotificationHelperStub()

            let key = Key(matchingKey: userKey)
            let builder = DefaultSplitFactoryBuilder()
            _ = builder.setHttpClient(httpClient)
            _ = builder.setReachabilityChecker(ReachabilityMock())
            _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
            _ = builder.setNotificationHelper(notificationHelper)
            let factory = builder.setApiKey(apiKey).setKey(key)
                .setConfig(config).build()!

            let client = factory.client

            var time = Date().unixTimestamp()

            let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

            client.on(event: SplitEvent.sdkReady) {
                sdkReadyExpectation.fulfill()
            }

            wait(for: [sdkReadyExpectation, sseExp], timeout: 10)
            time = Date().unixTimestamp() - time

            var times = [Int64]()
            for _ in 0 ..< 10 {
                notificationHelper.simulateApplicationDidEnterBackground()
                ThreadUtils.delay(seconds: 1)

                sseExp = XCTestExpectation()
                let time1 = Date().unixTimestamp()
                notificationHelper.simulateApplicationDidBecomeActive()

                wait(for: [sseExp], timeout: 10)
                times.append(Date().unixTimestamp() - time1)
            }

            XCTAssertTrue(time >= 2)

            for i in 0 ..< 10 {
                XCTAssertTrue(times[i] >= 2)
            }

            let semaphore = DispatchSemaphore(value: 0)
            client.destroy(completion: {
                _ = semaphore.signal()
            })
            semaphore.wait()
        }
    #endif

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
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.dummySseResponse(delay: self.sseConDelay).utf8))
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

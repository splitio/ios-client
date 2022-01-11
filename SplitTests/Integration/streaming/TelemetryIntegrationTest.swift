//
//  TelemetryIntegrationTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class TelemetryIntegrationTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var streamingBinding: TestStreamResponseBinding?
    let sseConnExp = XCTestExpectation(description: "sseConnExp")
    var queue = DispatchQueue(label: "hol", qos: .userInteractive)

    var configs: [TelemetryConfig]!
    var stats: [TelemetryStats]!

    var expSse: XCTestExpectation!
    var expConfig: XCTestExpectation!

    override func setUp() {
        configs = [TelemetryConfig]()
        stats = [TelemetryStats]()

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testConfigTelemetry() {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 5
        //splitConfig.isDebugModeEnabled = true

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5
        self.expConfig = XCTestExpectation()

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok


//        streamingBinding?.push(message:
//            StreamingIntegrationHelper.splitKillMessagge(splitName: splitName, defaultTreatment: "conta",
//                                                         timestamp: numbers[splitsChangesHits],
//                                                         changeNumber: numbers[splitsChangesHits]))
//

        wait(for: [expConfig], timeout: expTimeout)

        var config: TelemetryConfig?
        if configs.count > 0 {
            config = configs[0]
        }

        XCTAssertEqual(1, configs.count)
        XCTAssertTrue(config?.streamingEnabled ?? false)
        XCTAssertFalse(config?.httpProxyDetected ?? true)
        XCTAssertFalse(config?.impressionsListenerEnabled ?? true)
        XCTAssertTrue(config?.eventsQueueSize ?? 0 > 0)
        XCTAssertEqual(ImpressionsMode.optimized.intValue(), config?.impressionsMode ?? -1)
        XCTAssertTrue(config?.activeFactories ?? 0 > 0)
        XCTAssertTrue(config?.redundantFactories ?? 0 > 0)
        XCTAssertEqual(config?.rates?.events, splitConfig.eventsPushRate)
        XCTAssertEqual(config?.rates?.impressions, splitConfig.impressionRefreshRate)
        XCTAssertEqual(config?.rates?.splits, splitConfig.featuresRefreshRate)
        XCTAssertEqual(config?.rates?.mySegments, splitConfig.segmentsRefreshRate)
        XCTAssertEqual(config?.rates?.telemetry, splitConfig.telemetryRefreshRate)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }


    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):

                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 99999,
                                                                                                        till: 99999).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("metrics/config"):
                if let body = request.body?.stringRepresentation.utf8 {
                    if let config = try? Json.encodeFrom(json: String(body), to: TelemetryConfig.self) {
                        self.configs.append(config)
                    }
                }

                self.expConfig.fulfill()
                self.expConfig = XCTestExpectation()
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("metrics/usage"):
                return TestDispatcherResponse(code: 200)

            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
                self.sseConnExp.fulfill()
            return self.streamingBinding!
        }
    }
}




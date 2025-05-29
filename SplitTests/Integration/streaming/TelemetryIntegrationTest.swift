//
//  TelemetryIntegrationTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class TelemetryIntegrationTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var streamingBinding: TestStreamResponseBinding?
    var sseConnExp = XCTestExpectation(description: "sseConnExp")
    var queue = DispatchQueue(label: "hol", qos: .userInteractive)

    var timestamp = AtomicInt(100)

    var configs: [TelemetryConfig]!
    var stats: [TelemetryStats]!

    var expSse: XCTestExpectation?
    var expConfig: XCTestExpectation?
    var expStats: XCTestExpectation?
    var expImp: XCTestExpectation?
    var expEve: XCTestExpectation?

    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"

    override func setUp() {
        configs = [TelemetryConfig]()
        stats = [TelemetryStats]()

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testConfigTelemetry() {
        expConfig = XCTestExpectation()

        let splitConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 99999
        // splitConfig.isDebugModeEnabled = true

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok

        wait(for: [expConfig!], timeout: expTimeout)

        var config: TelemetryConfig?
        if !configs.isEmpty {
            config = configs[0]
        }

        XCTAssertEqual(1, configs.count)
        XCTAssertTrue(config?.streamingEnabled ?? false)
        XCTAssertFalse(config?.httpProxyDetected ?? true)
        XCTAssertFalse(config?.impressionsListenerEnabled ?? true)
        XCTAssertTrue(config?.eventsQueueSize ?? 0 > 0)
        XCTAssertEqual(ImpressionsMode.optimized.intValue(), config?.impressionsMode ?? -1)
        XCTAssertTrue(config?.activeFactories ?? 0 > 0)
        XCTAssertTrue(config?.redundantFactories ?? 0 >= 0)
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

    func testRuntimeAndSyncTelemetry() {
        expStats = XCTestExpectation()
        expImp = XCTestExpectation()
        expEve = XCTestExpectation()

        let splitConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.eventsPushRate = 99999
        // splitConfig.isDebugModeEnabled = true

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok

        _ = client.getTreatment("Welcome_Page_UI")
        _ = client.getTreatmentWithConfig("Welcome_Page_UI")
        _ = client.getTreatments(splits: ["Welcome_Page_UI", "testo23"], attributes: nil)
        _ = client.getTreatmentsWithConfig(splits: ["Welcome_Page_UI", "testo23"], attributes: nil)
        _ = client.track(trafficType: "tra1", eventType: "event1", value: 1.0)

        client.flush()

        wait(for: [expStats!, expImp!, expEve!], timeout: expTimeout)

        var statsItem: TelemetryStats?

        if !stats.isEmpty {
            statsItem = stats[0]
        }

        XCTAssertTrue(statsItem?.lastSynchronization?.splits ?? 0 > 0)
        XCTAssertTrue(statsItem?.lastSynchronization?.mySegments ?? 0 > 0)
        XCTAssertTrue(statsItem?.lastSynchronization?.impressions ?? 0 > 0)
        XCTAssertTrue(statsItem?.lastSynchronization?.events ?? 0 > 0)
        XCTAssertTrue(statsItem?.methodLatencies?.treatment?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.methodLatencies?.treatments?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.methodLatencies?.treatmentWithConfig?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.methodLatencies?.treatmentsWithConfig?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.methodLatencies?.track?.count ?? 0 > 0)

        XCTAssertEqual(1, statsItem?.eventsQueued)
        // Two feature flags, optimized mode
        XCTAssertEqual(2, statsItem?.impressionsQueued)

        XCTAssertEqual(0, statsItem?.segmentCount)
        XCTAssertEqual(33, statsItem?.splitCount)

        XCTAssertTrue(statsItem?.httpLatencies?.splits?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpLatencies?.mySegments?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpLatencies?.impressions?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpLatencies?.events?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpLatencies?.token?.count ?? 0 > 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testStreamingTelemetry() {
        expStats = XCTestExpectation()
        expImp = XCTestExpectation()
        expEve = XCTestExpectation()

        let splitConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.eventsPushRate = 99999
        // splitConfig.isDebugModeEnabled = true

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok

        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: nextTimestap(),
            publishers: 5,
            channel: kPrimaryChannel))

        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: nextTimestap(),
            publishers: 10,
            channel: kSecondaryChannel))

        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(
            timestamp: nextTimestap(),
            controlType: "STREAMING_PAUSED"))

        sseConnExp = XCTestExpectation()
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(
            timestamp: nextTimestap(),
            controlType: "STREAMING_RESUMED"))

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(
            timestamp: nextTimestap(),
            controlType: "STREAMING_DISABLED"))

        ThreadUtils.delay(seconds: 1)

        client.flush()

        wait(for: [expStats!], timeout: expTimeout)

        var statsItem: TelemetryStats?

        if !stats.isEmpty {
            statsItem = stats[0]
        }

        XCTAssertEqual(1, statsItem?.streamingEvents?.filter { $0.type == 0 }.count) // Connection stablished
        XCTAssertEqual(5, statsItem?.streamingEvents?.filter { $0.type == 10 }[0].data) // Occupancy pri
        XCTAssertEqual(10, statsItem?.streamingEvents?.filter { $0.type == 20 }[0].data) // Occupancy sec
        XCTAssertEqual(1, statsItem?.streamingEvents?.filter { $0.type == 30 && $0.data == 0 }.count) // status enabled
        XCTAssertEqual(1, statsItem?.streamingEvents?.filter { $0.type == 30 && $0.data == 1 }.count) // status disabled
        XCTAssertEqual(1, statsItem?.streamingEvents?.filter { $0.type == 30 && $0.data == 2 }.count) // status paused
        XCTAssertTrue(statsItem?.streamingEvents?.filter { $0.type == 50 }[0].data ?? 0 > 0) // status enabled
//        XCTAssertEqual(40012, statsItem?.streamingEvents?.filter { $0.type == 60 }[0].data) // Ably error
        XCTAssertEqual(2, statsItem?.streamingEvents?.filter { $0.type == 70 && $0.data == 0 }.count) // mode streaming
        XCTAssertEqual(2, statsItem?.streamingEvents?.filter { $0.type == 70 && $0.data == 1 }.count) // mode polling

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testStreamingAblyErrorAndSessionLength() {
        expStats = XCTestExpectation()
        expImp = XCTestExpectation()
        expEve = XCTestExpectation()

        let splitConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.eventsPushRate = 99999
        // splitConfig.isDebugModeEnabled = true

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)
        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok
        streamingBinding?.push(message: IntegrationHelper.ably40012Error())

        ThreadUtils.delay(seconds: 1)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()

        wait(for: [expStats!], timeout: expTimeout)

        var statsItem: TelemetryStats?

        if !stats.isEmpty {
            statsItem = stats[0]
        }

        XCTAssertEqual(40012, statsItem?.streamingEvents?.filter { $0.type == 60 }[0].data) // Ably error
        XCTAssertTrue(statsItem?.sessionLengthMs ?? 0 > 0)
    }

    func testHttpError() {
        expStats = XCTestExpectation(description: "Stats")
        expImp = XCTestExpectation(description: "Impressions")
        expEve = XCTestExpectation(description: "Events")
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildErrorTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = SplitClientConfig()
        splitConfig.telemetryConfigHelper = IntegrationHelper.enabledTelemetry()
        splitConfig.telemetryRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.eventsPushRate = 99999
        // splitConfig.isDebugModeEnabled = true

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout: TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("TIMEOUT")
        }

        wait(for: [sdkReadyExpectation, sseConnExp], timeout: expTimeout)
        _ = client.getTreatment("Welcome_Page_UI") // To generate impressions
        _ = client.getTreatments(splits: ["Welcome_Page_UI", "testo23"], attributes: nil)
        _ = client.track(trafficType: "tra1", eventType: "event1", value: 1.0) // To generate events

        streamingBinding?.push(message: ":keepalive") // send keep alive to confirm streaming connection ok

        client.flush()
        client.flush()

        wait(for: [expStats!, expEve!, expImp!], timeout: expTimeout)

        var statsItem: TelemetryStats?

        if !stats.isEmpty {
            statsItem = stats[0]
        }

        XCTAssertTrue(statsItem?.httpErrors?.splits?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpErrors?.mySegments?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpErrors?.impressions?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpErrors?.events?.count ?? 0 > 0)
        XCTAssertTrue(statsItem?.httpErrors?.token?.count ?? 0 > 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testConfig() {
        var res = [Bool]()
        for _ in 0 ..< 10000 {
            let config = SplitClientConfig()
            res.append(config.isTelemetryEnabled)
        }

        let count = res.filter { $0 == true }.count
        XCTAssertTrue(count < 30)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let changes = self.splitChanges()
                return TestDispatcherResponse(code: 200, data: Data(changes.utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isTelemetryConfigEndpoint() {
                if let body = request.body?.stringRepresentation.utf8 {
                    if let config = try? Json.decodeFrom(json: String(body), to: TelemetryConfig.self) {
                        self.configs.append(config)
                    }
                }

                self.expConfig?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isTelemetryUsageEndpoint() {
                if let body = request.body?.stringRepresentation.utf8 {
                    if let config = try? Json.decodeFrom(json: String(body), to: TelemetryStats.self) {
                        self.stats.append(config)
                    }
                }

                self.expStats?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isEventsEndpoint() {
                self.expEve?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isImpressionsEndpoint() {
                self.expImp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    var splitsError = true
    var mySegmentsError = true
    var impressionsError = true
    var eventsError = true
    var authError = true
    private func buildErrorTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            let errorResp = TestDispatcherResponse(code: 500)

            if request.isSplitEndpoint() {
                if self.splitsError {
                    self.splitsError = false
                    return errorResp
                }

                let changes = self.splitChanges()
                return TestDispatcherResponse(code: 200, data: Data(changes.utf8))
            }
            if request.isMySegmentsEndpoint() {
                if self.mySegmentsError {
                    self.mySegmentsError = false
                    return errorResp
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                if self.authError {
                    self.authError = false
                    return errorResp
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isTelemetryConfigEndpoint() {
                if let body = request.body?.stringRepresentation.utf8 {
                    if let config = try? Json.decodeFrom(json: String(body), to: TelemetryConfig.self) {
                        self.configs.append(config)
                    }
                }

                self.expConfig?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isTelemetryUsageEndpoint() {
                if let body = request.body?.stringRepresentation.utf8 {
                    if let config = try? Json.decodeFrom(json: String(body), to: TelemetryStats.self) {
                        self.stats.append(config)
                    }
                }

                self.expStats?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isEventsEndpoint() {
                print("Eve hit ")
                if self.eventsError {
                    self.eventsError = false
                    return errorResp
                }
                print("Eve hit fulfill")
                self.expEve?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isImpressionsEndpoint() {
                print("Imp hit")
                if self.impressionsError {
                    self.impressionsError = false
                    return errorResp
                }
                print("Imp hit fulfill")
                self.expImp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseConnExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func splitChanges() -> String {
        return IntegrationHelper.loadSplitChangeFileJson(name: "splitchanges_1", sourceClass: self) ?? IntegrationHelper
            .emptySplitChanges
    }

    private func nextTimestap() -> Int {
        return timestamp.addAndGet(1000)
    }
}

//
//  SdkUpdateStreamingTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class SdkUpdateStreamingTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuth = false
    var isSseConnected = false
    var streamingBinding: TestStreamResponseBinding?
    let mySegExp = XCTestExpectation(description: "MySeg exp")
    let splitsChgExp = XCTestExpectation(description: "Splits chg exp")
    let kMaxSseAuthRetries = 3
    var sseAuthHits = 0
    var sseConnHits = 0
    var mySegmentsHits = 0
    var splitsChangesHits = 0
    // treaments "on" -> sdk ready, "on" -> full ssync streaming
    // , "free", "contra", "off" -> Push messages

    var treatments = ["on", "on", "free", "conta", "off"]
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changes = [String]()
    var sseExp: XCTestExpectation!
    let kInitialChangeNumber = 1000

    var database: SplitDatabase!

    override func setUp() {
        database = TestingHelper.createTestDatabase(name: "GralIntegrationTest")
        splitsChangesHits = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
    }

    func testReady() {
        database.generalInfoDao.update(info: .splitsChangeNumber, longValue: 99999)
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcherNoChanges(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: HttpSessionMock(), requestManager: reqManager)
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999999
        splitConfig.segmentsRefreshRate = 9999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        splitConfig.impressionsMode = "DEBUG"
        // splitConfig.isDebugModeEnabled = true

        sseExp = XCTestExpectation()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        var sdkReadyTriggered = false
        var sdkUpdatedTriggered = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyTriggered = true
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedTriggered = true
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 10)

        streamingBinding?
            .push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok

        let sdkUpdateExp = XCTestExpectation()
        DispatchQueue.test.asyncAfter(deadline: .now() + 2) {
            sdkUpdateExp.fulfill()
        }
        wait(for: [sdkUpdateExp], timeout: 2)

        XCTAssertTrue(sdkReadyTriggered)
        XCTAssertFalse(sdkUpdatedTriggered)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSdkUpdateSplitsWhenNotificationArrives() {
        database.generalInfoDao.update(info: .splitsChangeNumber, longValue: 500)
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999999
        splitConfig.segmentsRefreshRate = 9999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        // splitConfig.isDebugModeEnabled = true
        sseExp = XCTestExpectation()
        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout = 5.0

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdateExpectation = XCTestExpectation(description: "SDK Update Expectation")

        var sdkReadyTriggered = false
        var sdkUpdatedTriggered = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyTriggered = true
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedTriggered = true
            sdkUpdateExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 5)
        streamingBinding?
            .push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok

        streamingBinding?.push(
            message:
            StreamingIntegrationHelper.splitUpdateMessage(
                timestamp: 1999999,
                changeNumber: 99999))
        wait(for: [sdkUpdateExpectation], timeout: expTimeout)

        XCTAssertTrue(sdkReadyTriggered)
        XCTAssertTrue(sdkUpdatedTriggered)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSdkUpdateMySegmentsWhenNotificationArrives() {
        database.generalInfoDao.update(info: .splitsChangeNumber, longValue: 500)
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcherNoSplitChanges(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: HttpSessionMock(), requestManager: reqManager)
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999999
        splitConfig.segmentsRefreshRate = 9999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = .verbose
        // splitConfig.isDebugModeEnabled = true
        sseExp = XCTestExpectation()
        let key = Key(matchingKey: "user_key")
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout = 5.0

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdateExpectation = XCTestExpectation(description: "SDK Update Expectation")

        var sdkReadyTriggered = false
        var sdkUpdatedTriggered = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyTriggered = true
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdatedTriggered = true
            sdkUpdateExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 5)
        streamingBinding?
            .push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok

//        streamingBinding?.push(message:
//            StreamingIntegrationHelper.mySegmentNoPayloadMessage(timestamp: 99999))
        let msg = TestingData.fullMembershipsNotificationUnboundedMessage(type: .mySegmentsUpdate)
        streamingBinding?.push(message: msg)

        wait(for: [sdkUpdateExpectation], timeout: expTimeout)

        XCTAssertTrue(sdkReadyTriggered)
        XCTAssertTrue(sdkUpdatedTriggered)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func getChanges(for hitNumber: Int) -> SplitChange {
        if hitNumber < numbers.count {
            let jsonData = Data(changes[hitNumber].utf8)
            return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
        }
        let jsonData = Data(IntegrationHelper.emptySplitChanges(since: 500, till: 500).utf8)
        return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let hitNumber = self.getAndUpdateHit()
                return TestDispatcherResponse(
                    code: 200,
                    data: try! Json.encodeToJsonData(TargetingRulesChange(
                        featureFlags: self.getChanges(for: hitNumber),
                        ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))))
            }
            if request.isMySegmentsEndpoint() {
                self.mySegmentsHits += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildTestDispatcherNoSplitChanges() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: self.numbers[0], till: self.numbers[0]).utf8))
            }

            if request.isMySegmentsEndpoint() {
                self.mySegmentsHits += 1
                let hit = self.mySegmentsHits
                var json = IntegrationHelper.emptyMySegments
                if hit > 2 {
                    var mySegments = [String]()
                    for i in 1 ... hit {
                        mySegments.append("segment\(i)")
                    }
                    json = IntegrationHelper.buildSegments(regular: mySegments)
                }
                return TestDispatcherResponse(code: 200, data: Data(json.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildTestDispatcherNoChanges() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
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
            self.sseConnHits += 1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {
                self.sseExp.fulfill()
            }
            return self.streamingBinding!
        }
    }

    private func getChanges(withTreatment: String, since: Int, till: Int) -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(since)
        change?.till = Int64(till)
        let split = change?.splits[0]
        if let partitions = split?.conditions?[2].partitions {
            let partition = partitions.filter { $0.treatment == withTreatment }
            partition[0].size = 100

            for partition in partitions where partition.treatment != withTreatment {
                partition.size = 0
            }
        }
        let targetingRulesChange = TargetingRulesChange(
            featureFlags: change!,
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))
        return (try? Json.encodeToJson(targetingRulesChange)) ?? ""
    }

    private func loadChanges() {
        for i in 0 ..< 5 {
            let change = getChanges(
                withTreatment: treatments[i],
                since: numbers[i],
                till: numbers[i])
            changes.insert(change, at: i)
        }
    }

    private func waitForUpdate(secs: UInt32 = 2) {
        sleep(secs)
    }

    private func getAndUpdateHit() -> Int {
        var hitNumber = 0
        DispatchQueue.test.sync {
            hitNumber = self.splitsChangesHits
            self.splitsChangesHits += 1
        }
        return hitNumber
    }
}

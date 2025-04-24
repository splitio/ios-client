//
//  StreamingMySegmentsSyncTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class StreamingMySegmentsSyncTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = "user_key"
    var isSseAuth = false
    var isSseConnected = false
    var streamingBinding: TestStreamResponseBinding?
    let mySegExp = XCTestExpectation(description: "MySeg exp")
    let splitsChgExp = XCTestExpectation(description: "Feature flags chg exp")
    let kMaxSseAuthRetries = 3
    var sseAuthHits = 0
    var sseConnHits = 0
    var mySegmentsHits = 0
    var splitsChangesHits = 0
    // treaments "on" -> sdk ready, "on" -> full ssync streaming
    // , "free", "contra", "off" -> Push messages
    var treatments = ["on", "on", "free", "conta", "off"]
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changes: String!
    var mySegments = [String]()
    var sseExp = XCTestExpectation()
    let kInitialChangeNumber = 1000
    var exp1: XCTestExpectation!
    var exp2: XCTestExpectation!
    var exp3: XCTestExpectation!
    let expCount = 3

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testInitMySegments() {
        initTest(type: .mySegmentsUpdate)
    }

    func testInitMyLargeSegments() {
        initTest(type: .myLargeSegmentsUpdate)
    }

    func initTest(type: NotificationType) {

        loadMySegments(type: type)
        loadChanges(type: type)
        var inResult = "free"
        if type == .myLargeSegmentsUpdate {
            inResult = "large_free"
        }

        exp1 = XCTestExpectation(description: "Exp1")
        exp2 = XCTestExpectation(description: "Exp2")
        exp3 = XCTestExpectation(description: "Exp3")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = .verbose

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let  expTimeout:  TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            print("Ready triggered")
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: expTimeout)
        
        // Sending first push to enable streaming
        streamingBinding?.push(message: ":keepalive")
        wait(for: [exp1], timeout: expTimeout)
        waitForUpdate(secs: 1)
        
        let splitName = "workm"
        let treatmentReady = client.getTreatment(splitName)

        var msg: String = TestingData.fullMembershipsNotificationUnboundedMessage(type: type, cn: numbers[0].asInt64(), delay: 0)
        streamingBinding?.push(message: msg)
        wait(for: [exp2], timeout: expTimeout)
        waitForUpdate(secs: 1)
        
        let treatmentFirst = client.getTreatment(splitName)

        msg = TestingData.fullMembershipsNotificationUnboundedMessage(type: type, cn: numbers[1].asInt64(), delay: 0)
        streamingBinding?.push(message: msg)
        wait(for: [exp3], timeout: expTimeout)
        waitForUpdate(secs: 1)

        let treatmentSec = client.getTreatment(splitName)

        msg = TestingData.fullMembershipsNotificationUnboundedMessage(type: type, cn: numbers[2].asInt64())
        streamingBinding?.push(message: msg)
        waitForUpdate(secs: 2)
        let treatmentOld = client.getTreatment(splitName)

        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual(inResult, treatmentFirst)
        XCTAssertEqual("on", treatmentSec)
        XCTAssertEqual("on", treatmentOld)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let hitNumber = self.splitsChangesHits
                self.splitsChangesHits+=1
                var change: String!
                if hitNumber == 0 {
                    change = self.changes
                } else {
                    change = IntegrationHelper.emptySplitChanges(since: 1000, till: 1000)
                }
                return TestDispatcherResponse(code: 200, data: Data(change.utf8))
            }
            if request.isMySegmentsEndpoint() {
                let hitNumber = self.mySegmentsHits
                self.mySegmentsHits+=1

                let respData = self.mySegments[hitNumber]
                switch hitNumber {
                case 1:
                    print("Exp 1 fired")
                    self.exp1.fulfill()
                case 2:
                    print("Exp 2 fired")
                    self.self.exp2.fulfill()
                case 3:
                    print("Exp 3 fired")
                    self.exp3.fulfill()
                default:
                    IntegrationHelper.tlog("Exp no fired \(hitNumber)")
                }
                return TestDispatcherResponse(code: 200, data: Data(respData.utf8))
            }
            if request.isAuthEndpoint() {
                self.sseAuthHits+=1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseConnHits+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            //DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.sseExp.fulfill()
            //}
            return self.streamingBinding!
        }
    }

    private func loadChanges(type: NotificationType) {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = 500
        change?.till = 500
    changes = (try? Json.encodeToJson(TargetingRulesChange(featureFlags: change!, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)))) ?? IntegrationHelper.emptySplitChanges
    }

    private func loadMySegments(type: NotificationType) {
        if type == .mySegmentsUpdate {
            for _ in 1..<10 {
                mySegments.append(IntegrationHelper.emptyMySegments)
            }
            mySegments.insert(IntegrationHelper.mySegments(names: ["new_segment"]), at: 2)
        } else {
            for _ in 1..<3 {
                mySegments.append(IntegrationHelper.emptyMySegments)
            }
            mySegments.append(TestingHelper.newAllSegmentsChangeJson(mls: ["new_large_segment"], mlsCn: 100))
            for _ in 1..<7 {
                mySegments.append(TestingHelper.newAllSegmentsChangeJson(mls: [], mlsCn: 200))
            }
        }
    }

    private func waitForUpdate(secs: UInt32 = 2) {
        sleep(secs)
    }
}





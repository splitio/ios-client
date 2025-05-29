//
//  StreamingSplitsSyncTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingSplitsSyncTest: XCTestCase {
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

    var exp1: XCTestExpectation!
    var exp2: XCTestExpectation!
    var exp3: XCTestExpectation!
    let expCount = 3

    override func setUp() {
        splitsChangesHits = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
    }

    func testInit() {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        // splitConfig.isDebugModeEnabled = true

        sseExp = XCTestExpectation()

        exp1 = XCTestExpectation(description: "Exp1")
        exp2 = XCTestExpectation(description: "Exp2")
        exp3 = XCTestExpectation(description: "Exp3")

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout = 5.0

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            IntegrationHelper.tlog("sssc TIMEOUT")
        }

        IntegrationHelper.tlog("step 0")
        wait(for: [sdkReadyExpectation, sseExp], timeout: 100)
        streamingBinding?
            .push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok

        // Wait for signal BUT give travis time to fire it
        wait(for: [exp1], timeout: expTimeout)
        waitForUpdate(secs: 1)

        let splitName = "workm"
        let treatmentReady = client.getTreatment(splitName)
        waitForUpdate(secs: 1)
        streamingBinding?.push(
            message:
            StreamingIntegrationHelper.splitUpdateMessage(
                timestamp: numbers[2],
                changeNumber: numbers[2]))
        wait(for: [exp2], timeout: expTimeout)
        waitForUpdate(secs: 1)

        let treatmentFirst = client.getTreatment(splitName)
        waitForUpdate(secs: 1)

        streamingBinding?.push(
            message:
            StreamingIntegrationHelper.splitUpdateMessage(
                timestamp: numbers[3],
                changeNumber: numbers[3]))
        wait(for: [exp3], timeout: expTimeout)
        waitForUpdate(secs: 1)
        let treatmentSec = client.getTreatment(splitName)

        streamingBinding?.push(
            message:
            StreamingIntegrationHelper.splitUpdateMessage(
                timestamp: 100,
                changeNumber: 100))
        waitForUpdate()
        let treatmentOld = client.getTreatment(splitName)

        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual("free", treatmentFirst)
        XCTAssertEqual("conta", treatmentSec)
        XCTAssertEqual("conta", treatmentOld)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func getChanges(for hitNumber: Int) -> Data {
        if hitNumber <= expCount {
            IntegrationHelper.tlog("changes \(hitNumber)")
            return Data(changes[hitNumber].utf8)
        }
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let hitNumber = self.getAndUpdateHit()
                switch hitNumber {
                case 1:
                    self.exp1.fulfill()
                case 2:
                    self.exp2.fulfill()
                case 3:
                    self.exp3.fulfill()
                default:
                    IntegrationHelper.tlog("Exp no fired \(hitNumber)")
                }

                return TestDispatcherResponse(code: 200, data: self.getChanges(for: hitNumber))
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

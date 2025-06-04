//
//  FlushTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class CdnByPassTest: XCTestCase {

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
    var splitsChangesHits = 0
    // treaments "on" -> sdk ready, "on" -> full ssync streaming
    // , "free", "contra", "off" -> Push messages

    var treatments = ["on", "on", "free", "conta", "off"]
    var numbers = [Int64]()
    var changes = [String]()
    var sseExp: XCTestExpectation!
    let kInitialChangeNumber = 1000

    var keepAliveExp: XCTestExpectation!
    var cdnByPassExp: XCTestExpectation!
    var cdnReceived = false
    var requestUrl: String?

    override func setUp() {
        requestUrl = nil
        for i in 1..<20 {
            numbers.append(Int64(100 * i))
        }
        cdnReceived = false
        splitsChangesHits = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
    }

    func testInit() {
        Spec.flagsSpec = "1.1"
        performTest(expectedRequestUrl: "https://sdk.split.io/api/splitChanges?s=1.1&since=1200&rbSince=-1&sets=c,nset1,nset2&till=1200")
    }

    func testInitWithoutSpec() {
        Spec.flagsSpec = ""
        performTest(expectedRequestUrl: "https://sdk.split.io/api/splitChanges?since=1200&rbSince=-1&sets=c,nset1,nset2&till=1200")
    }

    private func performTest(expectedRequestUrl: String) {
        let expTimeout = 15.0
        sseExp = XCTestExpectation()

        keepAliveExp = XCTestExpectation(description: "Exp1")
        cdnByPassExp = XCTestExpectation(description: "cdnByPassExp")

        let factory = createFactory()
        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        streamingBinding?.push(message: ":keepalive")

        wait(for: [keepAliveExp], timeout: expTimeout)

        let changeNumber = Int(numbers[12])

        streamingBinding?.push(message:
                                StreamingIntegrationHelper.splitUpdateMessage(timestamp: changeNumber,
                                                                              changeNumber: changeNumber))
        wait(for: [cdnByPassExp], timeout: expTimeout)


        XCTAssertTrue(cdnReceived)
        XCTAssertEqual(expectedRequestUrl, requestUrl)

        // 1 hit for sdk ready
        // 1 hit for full sync after streaming
        // 10 attempts without cdn by pass (till)
        // 1 with cdn by pass
        XCTAssertEqual(13, splitsChangesHits)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func getChanges(for hitNumber: Int) -> Data {
        if hitNumber < changes.count {
            return Data(changes[hitNumber].utf8)
        }
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                self.requestUrl = request.url.absoluteString
                let hitNumber = self.getAndUpdateHit()
                if hitNumber == 1 {
                    self.keepAliveExp.fulfill()
                }
                if request.url.absoluteString.contains("till") {
                    self.cdnReceived = true
                    self.cdnByPassExp.fulfill()
                }
                return TestDispatcherResponse(code: 200, data: self.getChanges(for: hitNumber))
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
            self.sseConnHits+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {
                self.sseExp.fulfill()
            }
            return self.streamingBinding!
        }
    }

    private func getChanges(withTreatment: String, since: Int64, till: Int64) -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(since)
        change?.till = Int64(till)
//        let split = change?.splits[0]
        var targetingRulesChange = TargetingRulesChange(featureFlags: change!, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))

        return (try? Json.encodeToJson(targetingRulesChange)) ?? ""
    }

    private func loadChanges() {
        for i in 0..<numbers.count {
            let num =  numbers[i]
            let till =  num
            let change = getChanges(withTreatment: "workm",
                                    since: num,
                                    till: till)
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
            self.splitsChangesHits+=1
        }
        return hitNumber
    }

    private func createFactory() -> SplitFactory {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        //splitConfig.isDebugModeEnabled = true
        splitConfig.cdnBackoffTimeBaseInSecs = 0
        splitConfig.sync = SyncConfig.builder()
            .addSplitFilter(SplitFilter.bySet(["nset1", "nset2", "c"]))
            .build()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        return builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!
    }
}

//
//  StreamingOccupancyTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class StreamingOccupancyTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"

    var mySegHitCount = 0
    var splitsHitCount = 0

    let kRefreshRate = 1

    var mySegExps = [XCTestExpectation]()
    var splitsChangesExps = [XCTestExpectation]()
    var mySegExpIndex = 0
    var splitsExpIndex = 0

    var waitForSplitChangesHit = true
    var waitForMySegmentsHit = false

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func testInit() {

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = kRefreshRate
        splitConfig.segmentsRefreshRate = kRefreshRate
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 5

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        var timestamp = 1000

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        createExpectations()

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)
        streamingBinding?.push(message: ":keepalive") // to confirm streaming connection ok
        sleep(1) // wait 1 sec to be sure that first syncall after sse conn is done
        mySegHitCount = 0
        splitsHitCount = 0
        // Should disable streaming
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(timestamp: timestamp,
                                                                                    publishers: 0,
                                                                                    channel: kPrimaryChannel))
        waitForHits()
        wait(for: [mySegExps[mySegExpIndex], splitsChangesExps[splitsExpIndex]], timeout: 7)
        let mySegHitAfterDisabled = mySegHitCount
        let splitHitAfterDisabled = splitsHitCount

        // Should enable streaming in secondary channel
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(timestamp: timestamp,
                                                                                    publishers: 1,
                                                                                    channel: kSecondaryChannel))
        justWait() // wait for polling to stop
        mySegHitCount = 0
        splitsHitCount = 0
        justWait() // wait a while to confirm no hits

        let mySegHitAfterSecEnabled = mySegHitCount
        let splitHitAfterSecEnabled = splitsHitCount

        // Should disable streaming in secondary channel and enable polling
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(timestamp: timestamp,
                                                                                    publishers: 0,
                                                                                    channel: kSecondaryChannel))
        mySegHitCount = 0
        splitsHitCount = 0
        waitForHits()
        wait(for: [mySegExps[mySegExpIndex], splitsChangesExps[splitsExpIndex]], timeout: 7) // expectations for hits when polling enabled
        let mySegHitAfterSecDisabled = mySegHitCount
        let splitHitAfterSecDisabled = splitsHitCount

        // Should disable streaming
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(timestamp: timestamp,
                                                                                    publishers: 1,
                                                                                    channel: kPrimaryChannel))
        justWait() // wait for polling to stop
        mySegHitCount = 0
        splitsHitCount = 0
        justWait() // if polling enabled on hit should occur

        let mySegHitAfterPriEnabled = mySegHitCount
        let splitHitAfterPriEnabled = splitsHitCount

        // Sending old timestamp notification. Nothing should change
        timestamp-=2000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(timestamp: timestamp,
                                                                                    publishers: 0,
                                                                                    channel: kPrimaryChannel))
        justWait() // if polling enabled on hit should occur

        let mySegHitAfterOldPriEnabled = mySegHitCount
        let splitHitAfterOldPriEnabled = splitsHitCount

        // Hits > 0 means polling enabled (channel pri and sec disabled)
        XCTAssertTrue(splitHitAfterDisabled > 0)
        XCTAssertTrue(mySegHitAfterDisabled > 0)

        // Hits == 0 means polling disabled (streaming enabled channel sec)
        XCTAssertEqual(0, splitHitAfterSecEnabled)
        XCTAssertEqual(0, mySegHitAfterSecEnabled)

        // Hits > 0 means polling enabled (channel sec disabled)
        XCTAssertTrue(mySegHitAfterSecDisabled > 0)
        XCTAssertTrue(splitHitAfterSecDisabled > 0)

        // Hits == 0 means polling disabled (streaming enabled channel pri)
        XCTAssertEqual(0, mySegHitAfterPriEnabled)
        XCTAssertEqual(0, splitHitAfterPriEnabled)

        // Hits == 0 means polling disabled (streaming enabled channel pri)
        XCTAssertEqual(0, mySegHitAfterOldPriEnabled)
        XCTAssertEqual(0, splitHitAfterOldPriEnabled)

    }

    private func waitForHits() {
        waitForMySegmentsHit = true
        waitForSplitChangesHit = true
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                self.splitsHitCount+=1
                self.checkHist(inSplits: true)
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges.utf8))
            case let(urlString) where urlString.contains("mySegments"):
                self.mySegHitCount+=1
                self.checkHist(inSplits: false)
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            case let(urlString) where urlString.contains("auth"):
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func justWait() {
        sleep(UInt32(Double(self.kRefreshRate) * 2))
    }

    private func checkHist(inSplits: Bool) {
        DispatchQueue.global().async {
            self.waitLoop(inSplits: inSplits)
        }
    }

    func waitLoop(inSplits: Bool) {
        var out = false
        while(!out) {
            justWait()
            let hits = inSplits ? self.splitsHitCount : self.mySegHitCount
            out = hits > 0
            if inSplits {
                if waitForMySegmentsHit {
                    waitForMySegmentsHit = false
                    mySegExps[mySegExpIndex].fulfill()
                    mySegExpIndex+=1
                }
            } else {
                if waitForSplitChangesHit {
                    waitForSplitChangesHit = false
                    splitsChangesExps[splitsExpIndex].fulfill()
                    splitsExpIndex+=1
                }
            }
        }
    }

    func createExpectations() {
        for _ in 1..<20 {
            mySegExps.append(XCTestExpectation())
            splitsChangesExps.append(XCTestExpectation())
        }
    }
}


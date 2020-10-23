//
//  StreamingControlTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class StreamingControlTest: XCTestCase {
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

    func testControl() {

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = kRefreshRate
        splitConfig.segmentsRefreshRate = kRefreshRate
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.isDebugModeEnabled = true

        let splitName = "workm"

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

        let treatmentReady = client.getTreatment(splitName)

        justWait() // wait to allow sync all

        // Should disable streaming
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_PAUSED"))
        waitForHits()
        wait(for: [mySegExps[mySegExpIndex],  splitsChangesExps[splitsExpIndex]], timeout: 7)

        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        justWait() // allow to my segments be updated
        let treatmentPaused = client.getTreatment(splitName)

        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_ENABLED"))
        justWait() // allow polling to stop
        timestamp+=1000

        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        justWait() // allow to my segments be updated
        let treatmentEnabled = client.getTreatment(splitName)

        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_DISABLED"))

        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        waitForHits()
        wait(for: [mySegExps[mySegExpIndex],  splitsChangesExps[splitsExpIndex]], timeout: 7)

        justWait()
        let treatmentDisabled = client.getTreatment(splitName)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual("on", treatmentPaused)
        XCTAssertEqual("free", treatmentEnabled)
        XCTAssertEqual("on", treatmentDisabled)
    }

    private func waitForHits() {
        waitForMySegmentsHit = true
        waitForSplitChangesHit = true
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let hit = self.splitsHitCount
                self.splitsHitCount+=1
                if hit == 0 {
                    return TestDispatcherResponse(code: 200, data: Data(self.splitChanges().utf8))
                }
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
        ThreadUtils.delay(seconds: Double(self.kRefreshRate) * 2.0)
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

    private func splitChanges() -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = 500
        change?.till = 1000
        return (try? Json.encodeToJson(change)) ?? IntegrationHelper.emptySplitChanges
    }
}

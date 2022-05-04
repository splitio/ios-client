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

    var mySegExp: XCTestExpectation!
    var splitsChangesExp: XCTestExpectation!

    var checkSplitChangesHit = false
    var checkMySegmentsHit = false

    var testFactory: TestSplitFactory!

    override func setUp() {
        testFactory = TestSplitFactory(userKey: "user_key")
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
    }

    func testControl() throws {

        let splitName = "workm"

        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        var timestamp = 1000

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 5)

        streamingBinding?.push(message: ":keepalive")

        let treatmentReady = client.getTreatment(splitName)

        startHitsCheck()

        // Should disable streaming and enable polling
        syncSpy.startPeriodicFetchingExp = XCTestExpectation()
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_PAUSED"))


        wait(for: [syncSpy.startPeriodicFetchingExp!], timeout: 5)

        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        // allow to my segments be updated
        startHitsCheck()
        wait(for: [mySegExp,  splitsChangesExp], timeout: 5)
        let treatmentPaused = client.getTreatment(splitName)


        syncSpy.stopPeriodicFetchingExp = XCTestExpectation()
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_RESUMED"))

        wait(for: [syncSpy.stopPeriodicFetchingExp!], timeout: 5) // Polling stopped once streaming enabled
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        wait() // allow to my segments be updated
        let treatmentEnabled = client.getTreatment(splitName)

        // Should disable streaming and enable polling
        syncSpy.startPeriodicFetchingExp = XCTestExpectation()
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
                                                                                  controlType: "STREAMING_DISABLED"))

        wait(for: [syncSpy.startPeriodicFetchingExp!], timeout: 5)
        timestamp+=1000
        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
                                                                                               segment: "new_segment"))
        startHitsCheck()
        wait(for: [mySegExp,  splitsChangesExp], timeout: 5)

        let treatmentDisabled = client.getTreatment(splitName)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual("on", treatmentPaused)
        XCTAssertEqual("free", treatmentEnabled)
        XCTAssertEqual("on", treatmentDisabled)

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
                let hit = self.splitsHitCount
                self.splitsHitCount+=1
                if hit == 0 {
                    return TestDispatcherResponse(code: 200, data: Data(self.splitChanges().utf8))
                }
                if self.checkSplitChangesHit {
                    self.splitsChangesExp.fulfill()
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            case let(urlString) where urlString.contains("mySegments"):
                if self.checkMySegmentsHit {
                    self.mySegExp.fulfill()
                }
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

    private func startHitsCheck() {
        splitsChangesExp = XCTestExpectation()
        mySegExp = XCTestExpectation()
        checkSplitChangesHit = true
        checkMySegmentsHit = true
    }

    private func wait() {
        ThreadUtils.delay(seconds: Double(self.kRefreshRate) * 2.0)
    }

    private func splitChanges() -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = 500
        change?.till = 1000
        return (try? Json.encodeToJson(change)) ?? IntegrationHelper.emptySplitChanges
    }
}

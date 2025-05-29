//
//  StreamingOccupancyTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class StreamingOccupancyTest: XCTestCase {
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"

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

    func testOccupancy() throws {
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        var timestamp = 1000

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)
        streamingBinding?.push(message: ":keepalive") // to confirm streaming connection ok

        // Should disable streaming and enable polling
        syncSpy.startPeriodicFetchingExp = XCTestExpectation()
        // Should disable streaming
        timestamp += 1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: timestamp,
            publishers: 0,
            channel: kPrimaryChannel))

        wait(for: [syncSpy.startPeriodicFetchingExp!], timeout: 5)
        let streamingDisabledPri = syncSpy.startPeriodicFetchingCalled

        // Should enable streaming in secondary channel
        syncSpy.stopPeriodicFetchingExp = XCTestExpectation()
        timestamp += 1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: timestamp,
            publishers: 1,
            channel: kSecondaryChannel))
        wait(for: [syncSpy.stopPeriodicFetchingExp!], timeout: 5)
        let streamingEnabledSec = syncSpy.stopPeriodicFetchingCalled

        syncSpy.startPeriodicFetchingCalled = false
        syncSpy.startPeriodicFetchingExp = XCTestExpectation()
        // Should disable streaming in secondary channel and enable polling
        timestamp += 1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: timestamp,
            publishers: 0,
            channel: kSecondaryChannel))
        wait(for: [syncSpy.startPeriodicFetchingExp!], timeout: 5) // expectations for hits when polling enabled
        let streamingDisabledSec = syncSpy.startPeriodicFetchingCalled

        syncSpy.stopPeriodicFetchingExp = XCTestExpectation()
        // Should disable streaming
        timestamp += 1000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: timestamp,
            publishers: 1,
            channel: kPrimaryChannel))

        wait(for: [syncSpy.stopPeriodicFetchingExp!], timeout: 5)
        let streamingEnabledPri = syncSpy.stopPeriodicFetchingCalled

        syncSpy.stopPeriodicFetchingCalled = false
        // Sending old timestamp notification. Nothing should change
        timestamp -= 2000
        streamingBinding?.push(message: StreamingIntegrationHelper.occupancyMessage(
            timestamp: timestamp,
            publishers: 0,
            channel: kPrimaryChannel))

        wait() // if polling enabled on hit should occur
        let oldTimestampDisabled = syncSpy.stopPeriodicFetchingCalled

        // Assert
        XCTAssertTrue(streamingDisabledPri)
        XCTAssertTrue(streamingEnabledSec)
        XCTAssertTrue(streamingDisabledSec)
        XCTAssertTrue(streamingEnabledPri)
        XCTAssertFalse(oldTimestampDisabled)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.checkSplitChangesHit {
                    self.splitsChangesExp.fulfill()
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }
            if request.isMySegmentsEndpoint() {
                if self.checkMySegmentsHit {
                    self.mySegExp.fulfill()
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
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
        print("WAIT OCCC 2")
        ThreadUtils.delay(seconds: Double(kRefreshRate) * 2.0)
    }
}

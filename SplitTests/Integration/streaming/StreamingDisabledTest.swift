//
//  StreamingDisabledTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class StreamingDisabledTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    let pollingExp = XCTestExpectation(description: "Polling conn")

    var mySegExp: XCTestExpectation!
    var splitsChangesExp: XCTestExpectation!

    var checkSplitChangesHit = false
    var checkMySegmentsHit = false

    var testFactory: TestSplitFactory!

    override func setUp() {
        testFactory = TestSplitFactory(userKey: IntegrationHelper.dummyUserKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
    }

    func testOccupancy() throws {
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        var timeOutFired = false
        var sdkReadyFired = false
        syncSpy.startPeriodicFetchingExp = pollingExp

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, pollingExp], timeout: 20)

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertTrue(isSseAuthHit)
        XCTAssertFalse(isSseHit)
        // Means polling enabled
        XCTAssertTrue(syncSpy.startPeriodicFetchingCalled)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func startHitsCheck() {
        splitsChangesExp = XCTestExpectation()
        mySegExp = XCTestExpectation()
        checkSplitChangesHit = true
        checkMySegmentsHit = true
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.sseDisabledResponse().utf8))
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}

//
//  SingleSyncTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 31-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SingleSyncTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = "key"

    var uniqueKeysHitCount = 0
    var impressionsCountHitCount = 0
    var impressionsHitCount = 0
    var eventsHitCount = 0
    var mySegmentsHitCount = 0
    var splitsHitCount = 0
    var sseAuthHitCount = 0

    var impExp: XCTestExpectation?
    var eveExp: XCTestExpectation?
    var impCountExp: XCTestExpectation?
    var uKeyExp: XCTestExpectation?
    var notificationHelper: NotificationHelperStub!

    let queue = DispatchQueue(label: "queue", target: .test)

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        notificationHelper = NotificationHelperStub()
        impExp = nil
        impressionsHitCount = 3
        eventsHitCount = 3
        mySegmentsHitCount = 0
        splitsHitCount = 0
        uniqueKeysHitCount = 3
        impressionsCountHitCount = 0
    }

    func testSingleSyncEnabledImpressionsOptmized() {
        let factory = buildFactory(impressionsMode: "OPTIMIZED")
        let client = factory.client
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 5)

        impCountExp = XCTestExpectation(description: "counts")
        for i in 0 ..< 3 {
            _ = factory.client(matchingKey: "key").getTreatment("TEST")
            _ = factory.client(matchingKey: "key\(i)").getTreatment("TEST")
            _ = client.track(eventType: "eve\(i)")

            impExp = XCTestExpectation(description: "impressions")
            eveExp = XCTestExpectation(description: "events")

            simulateBgFg()
            wait(for: [impExp!, eveExp!], timeout: 10)
        }
        wait(for: [impCountExp!], timeout: 10)

        XCTAssertEqual(1, splitsHitCount)
        XCTAssertEqual(4, mySegmentsHitCount) // One for key
        XCTAssertEqual(0, sseAuthHitCount)
        XCTAssertTrue(eventsHitCount > 3)
        XCTAssertTrue(impressionsHitCount > 3)
        XCTAssertTrue(impressionsCountHitCount > 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSingleSyncEnabledImpressionsDebug() {
        let factory = buildFactory(impressionsMode: "DEBUG")
        let client = factory.client
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 5)

        for i in 0 ..< 3 {
            _ = factory.client(matchingKey: "key\(i)").getTreatment("TEST")
            _ = client.track(eventType: "eve\(i)")

            impExp = XCTestExpectation(description: "impressions")
            eveExp = XCTestExpectation(description: "events")

            simulateBgFg()
            wait(for: [impExp!, eveExp!], timeout: 10)
        }

        XCTAssertEqual(1, splitsHitCount)
        XCTAssertEqual(4, mySegmentsHitCount) // One for key
        XCTAssertEqual(0, sseAuthHitCount)
        XCTAssertTrue(eventsHitCount > 3)
        XCTAssertTrue(impressionsHitCount > 3)
        XCTAssertEqual(0, impressionsCountHitCount)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testSingleSyncEnabledImpressionsNone() {
        let factory = buildFactory(impressionsMode: "NONE")
        let client = factory.client
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 5)

        impCountExp = XCTestExpectation(description: "counts")
        uKeyExp = XCTestExpectation(description: "UniqueKeys")
        for i in 0 ..< 3 {
            _ = factory.client(matchingKey: "key\(i)").getTreatment("TEST")
            _ = client.track(eventType: "eve\(i)")
            eveExp = XCTestExpectation(description: "events")
            simulateBgFg()
            wait(for: [eveExp!], timeout: 10)
        }
        // Disk writting could be slow in CI. Testing counts and keys here
        wait(for: [impCountExp!, uKeyExp!], timeout: 10)

        XCTAssertEqual(1, splitsHitCount)
        XCTAssertEqual(4, mySegmentsHitCount) // One for key
        XCTAssertEqual(0, sseAuthHitCount)
        XCTAssertTrue(eventsHitCount > 3)
        XCTAssertTrue(uniqueKeysHitCount > 0)
        XCTAssertTrue(impressionsCountHitCount > 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            print("URL: \(request.url.absoluteString)")
            if request.isSplitEndpoint() {
                let json = self.loadSplitsChangeFile()
                self.splitsHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(json.utf8))
            }

            if request.isMySegmentsEndpoint() {
                self.mySegmentsHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                self.sseAuthHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.impressionsHitCount += 1
                self.impExp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                self.eventsHitCount += 1
                self.eveExp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }

            if request.isImpressionsCountEndpoint() {
                self.impressionsCountHitCount += 1
                if self.impressionsCountHitCount == 1 {
                    self.impCountExp?.fulfill()
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isUniqueKeysEndpoint() {
                self.uniqueKeysHitCount += 1
                self.uKeyExp?.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            TestStreamResponseBinding.createFor(request: request, code: 200)
        }
    }

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json")
        else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }

    private func simulateBgFg() {
        // Unique keys and impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()
    }

    private func buildFactory(impressionsMode: String) -> SplitFactory {
        let splitConfig = SplitClientConfig()
        splitConfig.impressionsMode = impressionsMode
        splitConfig.trafficType = "user"
        splitConfig.syncEnabled = false
        splitConfig.streamingEnabled = true
        splitConfig.featuresRefreshRate = 1
        splitConfig.segmentsRefreshRate = 1
        splitConfig.impressionRefreshRate = 1
        splitConfig.impressionsCountsRefreshRate = 1
        splitConfig.eventsFirstPushWindow = 1
        splitConfig.eventsPushRate = 1
        splitConfig.uniqueKeysRefreshRate = 1
        splitConfig.logLevel = TestingHelper.testLogLevel

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        _ = builder.setNotificationHelper(notificationHelper)

        return builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!
    }
}

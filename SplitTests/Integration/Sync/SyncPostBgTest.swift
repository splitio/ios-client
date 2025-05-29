//
//  SyncPostBgTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SyncPostBgTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = "key0"
    var authHit = 0

    var mySegmentsHitCount = 0
    var changesHitCount = 0

    var notificationHelper: NotificationHelperStub!

    var changesExp: XCTestExpectation?
    var mySegmentsExp: XCTestExpectation?
    var authExp: XCTestExpectation?

    let queue = DispatchQueue(label: "queue", target: .test)
    let delays = [1, 1, 10, 10, 10, 10, 10, 10, 10, 10]
    var delaySum = 0

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        notificationHelper = NotificationHelperStub()
        mySegmentsHitCount = 0
        changesHitCount = 0
        ServiceConstants.values = ServiceConstants.Values(maxSyncPeriodInMillis: 3000)
    }

    func testSync() {
        mySegmentsExp = XCTestExpectation()
        authExp = XCTestExpectation()
        let factory = buildFactory()
        let client = factory.client
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 5)

        // Creating one more keys
        _ = factory.client(matchingKey: "key1").getTreatment("TEST")

        wait(for: [mySegmentsExp!], timeout: 5)
        mySegmentsExp = nil

        // Put counters in 0
        _ = takeChangesHitCount()
        _ = takeMySegmentsHitCount()

        simulateBgFg(forTime: 1.0)
        // Thread.sleep(forTimeInterval: 0.3) // Wait for a hit
        ThreadUtils.delay(seconds: 0.3)
        let changesHitCount1 = takeChangesHitCount()
        let mySegmentsHitCount1 = takeMySegmentsHitCount()

        changesExp = XCTestExpectation()
        mySegmentsExp = XCTestExpectation()
        simulateBgFg(forTime: 3.5)

        wait(for: [changesExp!, mySegmentsExp!], timeout: 5.0)
        let changesHitCount2 = takeChangesHitCount()
        let mySegmentsHitCount2 = takeMySegmentsHitCount()

        // Now, increasing auth delay time for a match bigger number than current LST
        // so, wait for the delay to be increased
        wait(for: [authExp!], timeout: 5.0)
        // Wait for changes to be applied
//        Thread.sleep(forTimeInterval: 0.3)
        ThreadUtils.delay(seconds: 1.0)
        // Put counters in 0
        _ = takeChangesHitCount()
        _ = takeMySegmentsHitCount()
        simulateBgFg(forTime: 3.0)

        Thread.sleep(forTimeInterval: 0.3) // Wait for a hit

        let changesHitCount3 = takeChangesHitCount()
        let mySegmentsHitCount3 = takeMySegmentsHitCount()

        Thread.sleep(forTimeInterval: 0.2)

        XCTAssertEqual(0, changesHitCount1)
        XCTAssertEqual(0, mySegmentsHitCount1)

        XCTAssertEqual(1, changesHitCount2)
        XCTAssertEqual(2, mySegmentsHitCount2) // One for key

        XCTAssertEqual(0, changesHitCount3)
        XCTAssertEqual(0, mySegmentsHitCount3)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func takeChangesHitCount() -> Int {
        queue.sync {
            let count = changesHitCount
            changesHitCount = 0
            return count
        }
    }

    private func takeMySegmentsHitCount() -> Int {
        queue.sync {
            let count = mySegmentsHitCount
            mySegmentsHitCount = 0
            return count
        }
    }

    private func increaseChangesHitCount() -> Int {
        queue.sync {
            changesHitCount += 1
            return changesHitCount
        }
    }

    private func increaseMySegmentsHitCount() -> Int {
        queue.sync {
            mySegmentsHitCount += 1
            return mySegmentsHitCount
        }
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            print("URL: \(request.url.absoluteString)")
            if request.isSplitEndpoint() {
                let json = self.loadSplitsChangeFile()
                _ = self.increaseChangesHitCount()
                self.changesExp?.fulfill()
                self.changesExp = nil
                return TestDispatcherResponse(code: 200, data: Data(json.utf8))
            }

            if request.isMySegmentsEndpoint() {
                let hit = self.increaseMySegmentsHitCount()
                if hit == 2 {
                    self.mySegmentsExp?.fulfill()
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                let delay = self.delays[self.authHit]
                self.delaySum += delay
                print("auth delay \(delay) for hit \(self.authHit) ==> delay sum \(self.delaySum)")
                self.authHit += 1
                if self.delaySum > 20 {
                    print("Auth fulfill")
                    self.authExp?.fulfill()
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.dummySseResponse(delay: delay).utf8))
            }
            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            if request.isEventsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            if request.isImpressionsCountEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isUniqueKeysEndpoint() {
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

    private func simulateBgFg(forTime time: Double = 0) {
        // Unique keys and impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        print("IN BG")
        // Thread.sleep(forTimeInterval: time)
        ThreadUtils.delay(seconds: time)
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()
        print("IN FG")
    }

    private func buildFactory() -> SplitFactory {
        let splitConfig = SplitClientConfig()
        splitConfig.trafficType = "user"
        splitConfig.streamingEnabled = true
        splitConfig.impressionRefreshRate = 999999
        splitConfig.impressionsCountsRefreshRate = 999999
        splitConfig.eventsFirstPushWindow = 999999
        splitConfig.eventsPushRate = 999999
        splitConfig.uniqueKeysRefreshRate = 999999
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

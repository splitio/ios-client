//
//  ImpressionsDedupTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07-Jul-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsDedupTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var firstSplitHit = true
    var sseExp: XCTestExpectation!
    var impExp: XCTestExpectation?
    var countExp: XCTestExpectation?
    var impressions: [String: [KeyImpression]]!
    var counts: [String: Int]!
    let queue = DispatchQueue(label: "queue", target: .test)
    var db: SplitDatabase!

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        impressions = [String: [KeyImpression]]()
        counts = [String: Int]()
        sseExp = XCTestExpectation(description: "Sse conn")
        impExp = nil
    }

    func testOptimized() {
        dedupTest(mode: "OPTIMIZED", impValues: [1, 1, 1], countValues: [99, 149, 159])
    }

    func testDebug() {
        dedupTest(mode: "DEBUG", impValues: [100, 150, 160], countValues: [0, 0, 0])
    }

    func dedupTest(mode: String, impValues: [Int], countValues: [Int]) {
        let notificationHelper = NotificationHelperStub()

        db = TestingHelper.createTestDatabase(name: "test")

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
//        splitConfig.impressionRefreshRate =
//        splitConfig.impressionsCountsRefreshRate = 1
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 999999
        splitConfig.eventsQueueSize = 99999
        splitConfig.eventsPushRate = 99999
        splitConfig.impressionsQueueSize = 99999
        splitConfig.impressionsChunkSize = 500
        splitConfig.impressionsMode = mode

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        for _ in 0 ..< 100 {
            _ = client.getTreatment("FACUNDO_TEST")
            _ = client.getTreatment("Test_Save_1")
            _ = client.getTreatment("TEST")
        }

        for _ in 0 ..< 50 {
            _ = client.getTreatment("Test_Save_1")
            _ = client.getTreatment("TEST")
        }

        for _ in 0 ..< 10 {
            _ = client.getTreatment("TEST")
        }
        sleep(1)

        IntegrationCoreDataHelper.observeChanges()
        let dbHashedImp = IntegrationCoreDataHelper.getDbExp(
            count: 3,
            entity: .hashedImpression,
            operation: CrudKey.update)

        // Impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()

        impExp = XCTestExpectation()
        // If sum of count values == 0, nothing to expect for
        countExp = (countValues.reduce(0) { $0 + $1 } == 0) ? nil : XCTestExpectation()
        // Just in case data was flushed before call get treatment
        // to have something to flush so that expectation doesn't fail
        _ = client.getTreatment("Tagging")

        // Flash data from cache
        client.flush()

        var expFor = [impExp!]
        expFor.append(dbHashedImp)

        if let exp = countExp {
            expFor.append(exp)
        }
        wait(for: expFor, timeout: 10)

        sleep(1)

        let hashedImp = db.hashedImpressionDao.getAll()

        XCTAssertEqual(impValues[0], impressions["FACUNDO_TEST"]?.count ?? 0)
        XCTAssertEqual(impValues[1], impressions["Test_Save_1"]?.count ?? 0)
        XCTAssertEqual(impValues[2], impressions["TEST"]?.count ?? 0)

        XCTAssertEqual(countValues[0], counts["FACUNDO_TEST"] ?? 0)
        XCTAssertEqual(countValues[1], counts["Test_Save_1"] ?? 0)
        XCTAssertEqual(countValues[2], counts["TEST"] ?? 0)

        XCTAssertEqual(3, hashedImp.count)

        IntegrationCoreDataHelper.stopObservingChanges()
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.firstSplitHit {
                    self.firstSplitHit = false
                    return TestDispatcherResponse(code: 200, data: Data(self.loadSplitsChangeFile().utf8))
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.queue.sync {
                    if let exp = self.impExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation.utf8 {
                        if let tests = try? Json.decodeFrom(json: String(body), to: [ImpressionsTest].self) {
                            for test in tests {
                                var imps = [KeyImpression]()
                                if let prevImp = self.impressions[test.testName] {
                                    imps.append(contentsOf: prevImp)
                                }
                                imps.append(contentsOf: test.keyImpressions)
                                self.impressions.updateValue(imps, forKey: test.testName)
                            }
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isImpressionsCountEndpoint() {
                self.queue.sync {
                    if let exp = self.countExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation.utf8 {
                        if let counts = try? Json.decodeFrom(json: String(body), to: ImpressionsCount.self) {
                            for count in counts.perFeature {
                                self.counts[count.feature] = count.count + (self.counts[count.feature] ?? 0)
                            }
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json")
        else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }
}

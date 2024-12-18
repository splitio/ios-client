//
//  ImpressionsToggleTest.swift
//  Split
//
//  Created by Gaston Thea on 18/12/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionsToggleTest: XCTestCase {

    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = "key"
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var firstSplitHit = true
    var sseExp: XCTestExpectation!
    var impExp: XCTestExpectation?
    var uniqueExp: XCTestExpectation?
    var countExp: XCTestExpectation?
    var uniqueKeys: [UniqueKeys]!
    var counts: [String: Int]!
    var impressionsHitCount = 0
    var impressionBody: String?
    let queue = DispatchQueue(label: "queue", target: .test)

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        uniqueKeys = [UniqueKeys]()
        counts = [String: Int]()
        sseExp = XCTestExpectation(description: "Sse conn")
        impExp = XCTestExpectation(description: "Imp exp")
        uniqueExp = XCTestExpectation(description: "Unique exp")
        countExp = XCTestExpectation(description: "Count exp")
        impressionsHitCount = 0
    }

    func testPeriodicRecording() {

        let notificationHelper = NotificationHelperStub()
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.impressionsMode = "debug"
        splitConfig.uniqueKeysRefreshRate = 1
        splitConfig.impressionRefreshRate = 1
        splitConfig.impressionsCountsRefreshRate = 1
        splitConfig.logLevel = .verbose

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        var exps = [XCTestExpectation]()
        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")


        exps.append(sdkReadyExpectation)

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        exps.append(sseExp)
        wait(for: exps, timeout: 5)

        _ = client.getTreatment("tracked")
        _ = client.getTreatment("not_tracked")

        sleep(1)

        // Unique keys and impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()

        sleep(1)
        client.flush()
        // Unique key should arrive if periodic recording works
        wait(for: [impExp!, uniqueExp!, countExp!], timeout: 5)

        XCTAssertEqual(uniqueKeys.count, 1)
        XCTAssertEqual(counts["not_tracked"], 1)
        XCTAssertNil(counts["tracked"])

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
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }
            
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.impressionsHitCount+=1
                self.queue.sync {
                    if let exp = self.impExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation {
                        self.impressionBody = body
                        print("imp body: \(self.impressionBody ?? "default value")")
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
            
            if request.isUniqueKeysEndpoint() {
                self.queue.sync {
                    if let body = request.body?.stringRepresentation.utf8 {
                        if let keys = try? Json.decodeFrom(json: String(body), to: UniqueKeys.self) {
                            self.uniqueKeys.append(keys)
                        }
                    }
                    if let exp = self.uniqueExp {
                        exp.fulfill()
                    }
                }
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_toggle", type: "json") else {
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

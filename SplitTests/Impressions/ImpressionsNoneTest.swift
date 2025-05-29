//
//  ImpressionsNoneTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsNoneTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = "key"
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var firstSplitHit = true
    var sseExp: XCTestExpectation!
    var impExp: XCTestExpectation?
    var countExp: XCTestExpectation?
    var uniqueKeys: [UniqueKeys]!
    var counts: [String: Int]!
    var impressionsHitCount = 0
    let queue = DispatchQueue(label: "queue", target: .test)

    enum Splits: Int {
        case facundoTest
        case testSave1
        case test
        case testing
        case aNewSplit2
        case testStringWithoutAttr
        case testo2222

        var str: String {
            switch self {
            case .facundoTest:
                return "FACUNDO_TEST"
            case .testSave1:
                return "Test_Save_1"
            case .test:
                return "TEST"
            case .testing:
                return "testing"
            case .aNewSplit2:
                return "a_new_split_2"
            case .testStringWithoutAttr:
                return "test_string_without_attr"
            case .testo2222:
                return "testo2222"
            }
        }
    }

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        uniqueKeys = [UniqueKeys]()
        counts = [String: Int]()
        sseExp = XCTestExpectation(description: "Sse conn")
        impExp = nil
        impressionsHitCount = 0
    }

    func testCorrectData() {
        let notificationHelper = NotificationHelperStub()

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 999999
        splitConfig.eventsQueueSize = 99999
        splitConfig.eventsPushRate = 99999
        splitConfig.impressionsQueueSize = 99999
        splitConfig.impressionsChunkSize = 500

//        splitConfig.impressionsMode = "none" // Currently unavailable
        splitConfig.impressionsMode = "NONE"
        splitConfig.uniqueKeysRefreshRate = 9999

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        var clients = [SplitClient]()
        var exps = [XCTestExpectation]()
        clients.append(factory.client)
        for i in 1 ..< 3 {
            let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
            let client = factory.client(matchingKey: "key\(i)")
            clients.append(client)
            exps.append(sdkReadyExpectation)

            client.on(event: SplitEvent.sdkReady) {
                sdkReadyExpectation.fulfill()
            }

            client.on(event: SplitEvent.sdkReadyTimedOut) {
                sdkReadyExpectation.fulfill()
            }
        }

        exps.append(sseExp)
        wait(for: exps, timeout: 20)

        for i in 0 ..< clients.count {
            let client = clients[i]
            switch i {
            case 0:
                for _ in 0 ..< 100 {
                    _ = client.getTreatment(Splits.facundoTest.str)
                    _ = client.getTreatment(Splits.testSave1.str)
                    _ = client.getTreatment(Splits.test.str)
                }
            case 1:
                for _ in 0 ..< 50 {
                    _ = client.getTreatment(Splits.testSave1.str)
                    _ = client.getTreatment(Splits.testing.str)
                }

            case 2:
                for _ in 0 ..< 10 {
                    _ = client.getTreatment(Splits.aNewSplit2.str)
                    _ = client.getTreatment(Splits.testStringWithoutAttr.str)
                    _ = client.getTreatment(Splits.test.str)
                    _ = client.getTreatment(Splits.testo2222.str)
                }
            default:
                print("do nothing")
            }
        }

        let countsExp = [
            Splits.facundoTest: 100,
            Splits.testSave1: 150,
            Splits.test: 110,
            Splits.testing: 50,
            Splits.aNewSplit2: 10,
            Splits.testStringWithoutAttr: 10,
            Splits.testo2222: 10,
        ]

        sleep(1)

        // Unique keys and impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()

        // Wait to make sure data is stored
        sleep(1)

        // Now calling flush to record data
        clients[0].flush()

        impExp = XCTestExpectation()
        countExp = XCTestExpectation()

        wait(for: [impExp!, countExp!], timeout: 10)

        sleep(1)

        var keys = [UniqueKey]()
        var features = [String: Set<String>]()
        if !uniqueKeys.isEmpty {
            keys.append(contentsOf: uniqueKeys[0].keys)
        }

        if keys.count > 2 { // It means we have all the keys
            for key in keys {
                features[key.userKey] = keys.filter { $0.userKey == key.userKey }[0].features
            }
        }

        XCTAssertEqual(0, impressionsHitCount)
        XCTAssertEqual(1, uniqueKeys.count)
        XCTAssertEqual(3, keys.count)

        XCTAssertTrue(features["key"]?.contains(Splits.facundoTest.str) ?? false)
        XCTAssertTrue(features["key"]?.contains(Splits.testSave1.str) ?? false)
        XCTAssertTrue(features["key"]?.contains(Splits.test.str) ?? false)

        XCTAssertTrue(features["key1"]?.contains(Splits.testSave1.str) ?? false)
        XCTAssertTrue(features["key1"]?.contains(Splits.testing.str) ?? false)

        XCTAssertTrue(features["key2"]?.contains(Splits.aNewSplit2.str) ?? false)
        XCTAssertTrue(features["key2"]?.contains(Splits.testStringWithoutAttr.str) ?? false)
        XCTAssertTrue(features["key2"]?.contains(Splits.test.str) ?? false)
        XCTAssertTrue(features["key2"]?.contains(Splits.testo2222.str) ?? false)

        XCTAssertEqual(countsExp[Splits.facundoTest], counts[Splits.facundoTest.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.testSave1], counts[Splits.testSave1.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.test], counts[Splits.test.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.testSave1], counts[Splits.testSave1.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.testing], counts[Splits.testing.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.aNewSplit2], counts[Splits.aNewSplit2.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.testStringWithoutAttr], counts[Splits.testStringWithoutAttr.str] ?? 0)
        XCTAssertEqual(countsExp[Splits.testo2222], counts[Splits.testo2222.str] ?? 0)

        let semaphore = DispatchSemaphore(value: 0)
        for i in 1 ..< clients.count {
            let client = clients[0]
            if i > clients.count - 1 {
                client.destroy()
            } else {
                client.destroy(completion: {
                    _ = semaphore.signal()
                })
                semaphore.wait()
            }
        }
    }

    func testPeriodicRecording() {
        let notificationHelper = NotificationHelperStub()
        let splitConfig = SplitClientConfig()
        splitConfig.impressionsMode = "none" // Currently unavailable
        splitConfig.uniqueKeysRefreshRate = 1

        let key = Key(matchingKey: userKey)
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

        for _ in 0 ..< 10 {
            _ = client.getTreatment(Splits.aNewSplit2.str)
            _ = client.getTreatment(Splits.testStringWithoutAttr.str)
            _ = client.getTreatment(Splits.test.str)
            _ = client.getTreatment(Splits.testo2222.str)
        }

        sleep(1)

        // Unique keys and impressions count are saved on app bg
        // Here that situation is simulated
        notificationHelper.simulateApplicationDidEnterBackground()
        // Make app active again
        notificationHelper.simulateApplicationDidBecomeActive()

        impExp = XCTestExpectation()

        // Unique key should arrive if periodic recording works
        wait(for: [impExp!], timeout: 5)

        XCTAssertTrue(!uniqueKeys.isEmpty)

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
                self.impressionsHitCount += 1
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
                    if let exp = self.impExp {
                        exp.fulfill()
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

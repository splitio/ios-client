//
//  TelemetryTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 16-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class TelemetryTest: XCTestCase {

    var telemetryStorage: TelemetryStorage!
    var streamingBinding: TestStreamResponseBinding?
    var splitDatabase: SplitDatabase!
    var session: HttpSessionMock!
    var reqManager: HttpRequestManagerTestDispatcher!
    var httpClient: HttpClient!
    static let userKey = IntegrationHelper.dummyUserKey
    let key = Key(matchingKey: userKey)
    let apiKey = IntegrationHelper.dummyApiKey
    let splitConfig: SplitClientConfig = TestingHelper.basicStreamingConfig()
    var builder: DefaultSplitFactoryBuilder!


    override func setUp() {
        telemetryStorage = InMemoryTelemetryStorage()
        splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test")
        // To allow firing ready from cache
        splitDatabase.splitDao.insertOrUpdate(split: TestingHelper.buildSplit(name: "some_split", treatment: "t1"))

        session = HttpSessionMock()
        reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)


        builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        _ = builder.setTelemetryStorage(telemetryStorage)
    }

    func testReadyTime() {

        let timeUntilReadyBefore = telemetryStorage.getTimeUntilReady()
        let timeUntilReadyFromCacheBefore = telemetryStorage.getTimeUntilReadyFromCache()

        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExp = XCTestExpectation()
        let sdkReadyFromCacheExp = XCTestExpectation()

        client.on(event: SplitEvent.sdkReadyFromCache) {
            sdkReadyFromCacheExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        wait(for: [sdkReadyFromCacheExp, sdkReadyExp], timeout: 10)

        let timeUntilReady = telemetryStorage.getTimeUntilReady()
        let timeUntilReadyFromCache = telemetryStorage.getTimeUntilReadyFromCache()

        XCTAssertEqual(0, timeUntilReadyBefore)
        XCTAssertEqual(0, timeUntilReadyFromCacheBefore)
        XCTAssertTrue(timeUntilReady > 0)
        XCTAssertTrue(timeUntilReadyFromCache > 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testFactoryCount() {

        let activeBefore = telemetryStorage.getActiveFactories()
        let redundantBefore = telemetryStorage.getRedundantFactories()

        let factoryCount = 6

        var factories = [SplitFactory]()
        var exps = [XCTestExpectation]()

        for i in 0..<factoryCount {
            let sdkReadyExp = XCTestExpectation()
            let sdkReadyFromCacheExp = XCTestExpectation()
            exps.append(sdkReadyExp)
            exps.append(sdkReadyFromCacheExp)

            let apiKey = "apiKey_\(i % 2)"
            let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

            factories.append(factory)

            let client = factory.client

            client.on(event: SplitEvent.sdkReadyFromCache) {
                sdkReadyFromCacheExp.fulfill()
            }

            client.on(event: SplitEvent.sdkReady) {
                sdkReadyExp.fulfill()
            }
        }

        wait(for: exps, timeout: 10)

        let active = telemetryStorage.getActiveFactories()
        let redundant = telemetryStorage.getRedundantFactories()

        XCTAssertEqual(0, activeBefore)
        XCTAssertEqual(0, redundantBefore)

        XCTAssertEqual(2, active)
        XCTAssertEqual(2, redundant) // 2 is ok, because only has redundat for one factory

        for factory in factories {
            let client = factory.client
            let semaphore = DispatchSemaphore(value: 0)
            client.destroy(completion: {
                _ = semaphore.signal()
            })
            semaphore.wait()
        }
    }

    func testNonReadyEvaluation() {
        let treatmentManager = createTreatmentManager()

        let before = telemetryStorage.getNonReadyUsages()
        let _ = treatmentManager.getTreatment("SPLIT", attributes: nil)
        let _ = treatmentManager.getTreatment("SPLIT", attributes: nil)
        let _ = treatmentManager.getTreatment("SPLIT", attributes: nil)

        let after = telemetryStorage.getNonReadyUsages()

        XCTAssertEqual(0, before)
        XCTAssertEqual(3, after)
    }

    override func tearDown() {
    }

    func createTreatmentManager() -> TreatmentManager {
        let splitHelper = SplitHelper()
        let splitsStorage = SplitsStorageStub()
        let split = splitHelper.createDefaultSplit(named: "SPLIT")
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split], archivedSplits: [],
                                                               changeNumber: -1, updateTimestamp: 100))
        let mySegmentsStorage = MySegmentsStorageStub()

        let key = Key(matchingKey: "CUSTOMER_ID")
        let client = InternalSplitClientStub(splitsStorage: splitsStorage,
                                             mySegmentsStorage: mySegmentsStorage)
        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = false
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFromCacheFired = false
        eventsManager.isSplitsReadyFromCacheFired = true

        return DefaultTreatmentManager(evaluator: DefaultEvaluator(splitClient: client),
                                       key: key, splitConfig: SplitClientConfig(),
                                       eventsManager: eventsManager,
                                       impressionLogger: ImpressionsLoggerStub(),
                                       telemetryProducer: telemetryStorage,
                                       attributesStorage: DefaultAttributesStorage(),
                                       keyValidator: DefaultKeyValidator(),
                                       splitValidator: DefaultSplitValidator(splitsStorage: splitsStorage),
                                       validationLogger: ValidationMessageLoggerStub())
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}

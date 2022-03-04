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

    let splitName = "some_split"


    override func setUp() {
        splitConfig.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: true)
        telemetryStorage = InMemoryTelemetryStorage()
        splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test")
        // To allow firing ready from cache
        splitDatabase.splitDao.insertOrUpdate(split: TestingHelper.buildSplit(name: splitName, treatment: "t1"))

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

    func testOnlyReadyTime() {
        splitDatabase.splitDao.delete(["some_split"]) // remove split to avoid SDK Ready from cache
        let timeUntilReadyBefore = telemetryStorage.getTimeUntilReady()
        let timeUntilReadyFromCacheBefore = telemetryStorage.getTimeUntilReadyFromCache()
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExp = XCTestExpectation()
        var readyFromCacheFired = false

        client.on(event: SplitEvent.sdkReadyFromCache) {
            readyFromCacheFired = true
        }

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        wait(for: [sdkReadyExp], timeout: 10)

        let timeUntilReady = telemetryStorage.getTimeUntilReady()
        let timeUntilReadyFromCache = telemetryStorage.getTimeUntilReadyFromCache()

        XCTAssertEqual(0, timeUntilReadyBefore)
        XCTAssertEqual(0, timeUntilReadyFromCacheBefore)
        XCTAssertTrue(timeUntilReady > 0)
        XCTAssertEqual(0, timeUntilReadyFromCache)
        XCTAssertFalse(readyFromCacheFired)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testEvaluationRecording() {
        let latenciesInit = telemetryStorage.popMethodLatencies()
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExp = XCTestExpectation()

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        wait(for: [sdkReadyExp], timeout: 10)

        for _ in 0..<10 {
            _ = client.getTreatment(splitName)
            _ = client.getTreatments(splits: [splitName], attributes: nil)
            _ = client.getTreatmentWithConfig(splitName)
            _ = client.getTreatmentsWithConfig(splits: [splitName], attributes: nil)
            _ = client.track(trafficType: "Some", eventType: "pepe")
        }

        let latencies = telemetryStorage.popMethodLatencies()
        let latenciesAfter = telemetryStorage.popMethodLatencies()

        XCTAssertEqual(0, sum(latenciesInit.treatment))
        XCTAssertEqual(0, sum(latenciesInit.treatments))
        XCTAssertEqual(0, sum(latenciesInit.treatmentWithConfig))
        XCTAssertEqual(0, sum(latenciesInit.treatmentsWithConfig))
        XCTAssertEqual(0, sum(latenciesInit.track))

        XCTAssertTrue(sum(latencies.treatment) > 0)
        XCTAssertTrue(sum(latencies.treatments) > 0)
        XCTAssertTrue(sum(latencies.treatmentWithConfig) > 0)
        XCTAssertTrue(sum(latencies.treatmentsWithConfig) > 0)
        XCTAssertTrue(sum(latencies.track) > 0)

        XCTAssertEqual(0, sum(latenciesAfter.treatment))
        XCTAssertEqual(0, sum(latenciesAfter.treatments))
        XCTAssertEqual(0, sum(latenciesAfter.treatmentWithConfig))
        XCTAssertEqual(0, sum(latenciesAfter.treatmentsWithConfig))
        XCTAssertEqual(0, sum(latenciesAfter.track))

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
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

    func sum(_ values: [Int]?) -> Int {
        guard let values = values else { return 0 }
        return values.reduce(0)  { return $0 + $1 }
    }

    func createTreatmentManager() -> TreatmentManager {
        let splitHelper = SplitHelper()
        let splitsStorage = SplitsStorageStub()
        let split = splitHelper.createDefaultSplit(named: "SPLIT")
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split], archivedSplits: [],
                                                               changeNumber: -1, updateTimestamp: 100))
        let mySegmentsStorage = OneKeyMySegmentsStorageStub()

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

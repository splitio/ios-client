//
//  InitialCacheTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class InitialCacheTest: XCTestCase {
    var globalCacheReadyFired: Atomic<Bool>!
    var globalReadyFired: Atomic<Bool>!
    var jsonChanges: [String]!
    var changes: [SplitChange]!
    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changeHitIndex: AtomicInt!
    var receivedChangeNumber: [Int64]!
    var cachedSplit: Split?
    var splitsQueryString = ""

    override func setUp() {
        receivedChangeNumber = Array(repeating: 0, count: 100)
        globalCacheReadyFired = Atomic(false)
        globalReadyFired = Atomic(false)
        changeHitIndex = AtomicInt(0) // First hit will be with index == 0. Index == 0 if for cache
        changes = [SplitChange]()
        jsonChanges = [String]()
        loadChangesExpired()
    }

    func testExpiredCache() {
        IntegrationCoreDataHelper.observeChanges()
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 3,
            entity: .generalInfo,
            operation: CrudKey.insert)

        let splitDatabase = TestingHelper.createTestDatabase(name: "expired_cache")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit!)
        splitDatabase.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 10)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 300)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        wait(for: [dbExp], timeout: 10.0)

        print("Setup completed, starting test")

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        var treatmentCache = ""
        var treatmentReady = ""

        client.on(event: SplitEvent.sdkReadyFromCache) {
            treatmentCache = client.getTreatment(self.splitName)
            cacheReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReady) {
            treatmentReady = client.getTreatment(self.splitName)
            readyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp, readyExp], timeout: 10)

        client.destroy()

        XCTAssertEqual(-1, receivedChangeNumber[0])
        XCTAssertEqual("on0", treatmentCache)
        XCTAssertEqual("on0", treatmentReady)
    }

    func testClearExpiredCache() {
        IntegrationCoreDataHelper.observeChanges()
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 3,
            entity: .generalInfo,
            operation: CrudKey.insert)

        let splitDatabase = TestingHelper.createTestDatabase(name: "expired_cache")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit!)
        splitDatabase.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 10)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 300)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        wait(for: [dbExp], timeout: 10.0)

        print("Setup completed, starting test")

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildNoChangesTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        var treatmentCache = ""
        var treatmentReady = ""

        client.on(event: SplitEvent.sdkReadyFromCache) { [weak self] in
            guard let self = self else { return }

            treatmentCache = client.getTreatment(self.splitName)
            cacheReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReady) { [weak self] in
            guard let self = self else { return }

            treatmentReady = client.getTreatment(self.splitName)
            readyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp, readyExp], timeout: 10)

        XCTAssertEqual(-1, receivedChangeNumber[0])
        XCTAssertEqual("control", treatmentCache)
        XCTAssertEqual("control", treatmentReady)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testNoClearNoExpiredCache() {
        IntegrationCoreDataHelper.observeChanges()
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 3,
            entity: .generalInfo,
            operation: CrudKey.insert)

        let splitDatabase = TestingHelper.createTestDatabase(name: "expired_cache")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit!)
        splitDatabase.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: Date().unixTimestamp())
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 300)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        wait(for: [dbExp], timeout: 10.0)

        print("Setup completed, starting test")

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildNoChangesTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        var treatmentCache = ""
        var treatmentReady = ""

        client.on(event: SplitEvent.sdkReadyFromCache) {
            treatmentCache = client.getTreatment(self.splitName)
            cacheReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReady) {
            treatmentReady = client.getTreatment(self.splitName)
            readyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp, readyExp], timeout: 10)

        XCTAssertEqual(300, receivedChangeNumber[0])
        XCTAssertEqual("boom", treatmentCache)
        XCTAssertEqual("boom", treatmentReady)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testClearChangedSplitFilter() throws {
        IntegrationCoreDataHelper.observeChanges()
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 4,
            entity: .generalInfo,
            operation: CrudKey.insert)

        let splitInFilter = "sample1"
        let splitDatabase = TestingHelper.createTestDatabase(name: "expired_cache")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit!)
        splitDatabase.splitDao.insertOrUpdate(split: TestingHelper.buildSplit(name: splitInFilter, treatment: "t1"))
        splitDatabase.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: Date().unixTimestamp())
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 300)
        splitDatabase.generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "")
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        wait(for: [dbExp], timeout: 10.0)

        print("Setup completed, starting test")

        let split = TestingHelper.buildSplit(name: splitInFilter, treatment: "t2")
        let change = SplitChange(splits: [split], since: 9000, till: 9000)
        jsonChanges.removeAll()
        jsonChanges.append(try Json.encodeToJson(TargetingRulesChange(
            featureFlags: change,
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))))

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        let syncConfig = SyncConfig.builder()
            .addSplitFilter(SplitFilter.byName([splitInFilter]))
            .build()

        splitConfig.sync = syncConfig
        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        var treatmentCache1 = ""
        var treatmentCache2 = ""
        var treatmentReady1 = ""
        var treatmentReady2 = ""

        client.on(event: SplitEvent.sdkReadyFromCache) {
            treatmentCache1 = client.getTreatment(self.splitName)
            treatmentCache2 = client.getTreatment(splitInFilter)
            cacheReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReady) {
            treatmentReady1 = client.getTreatment(self.splitName)
            treatmentReady2 = client.getTreatment(splitInFilter)
            readyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp, readyExp], timeout: 10)

        XCTAssertEqual(-1, receivedChangeNumber[0])
        XCTAssertEqual("control", treatmentCache1)
        XCTAssertEqual("t1", treatmentCache2)
        XCTAssertEqual("control", treatmentReady1)
        XCTAssertEqual("t2", treatmentReady2)
        XCTAssertTrue(splitsQueryString.contains("names=sample1"))

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testFlagsSpecChanged() {
        IntegrationCoreDataHelper.observeChanges()
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 3,
            entity: .generalInfo,
            operation: CrudKey.insert)

        let splitDatabase = TestingHelper.createTestDatabase(name: "expired_cache")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit!)
        splitDatabase.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 10)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 300)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: "1.1")

        wait(for: [dbExp], timeout: 10.0)

        print("Setup completed, starting test")

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()

        let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        var treatmentCache = ""
        var treatmentReady = ""

        var readyCacheNotFired = true
        client.on(event: SplitEvent.sdkReadyFromCache) {
            treatmentCache = client.getTreatment(self.splitName)
            readyCacheNotFired = false
        }

        client.on(event: SplitEvent.sdkReady) {
            treatmentReady = client.getTreatment(self.splitName)
            readyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 10)

        client.destroy()

        XCTAssertEqual("on0", treatmentCache)
        XCTAssertEqual("on0", treatmentReady)
        XCTAssertFalse(readyCacheNotFired)
    }

    private func getChanges(for hitNumber: Int) -> Data {
        if hitNumber < jsonChanges.count {
            return Data(jsonChanges[hitNumber].utf8)
        }
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                ThreadUtils.delay(seconds: 0.3) // Simulate network
                let changesIndex = self.changeHitIndex.getAndAdd(1)
                if changesIndex < self.numbers.count {
                    self.receivedChangeNumber[changesIndex] = request.parameters?["since"] as? Int64 ?? 0
                    self.splitsQueryString = request.url.absoluteString
                    return TestDispatcherResponse(code: 200, data: self.getChanges(for: changesIndex))
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 10000, till: 10000).utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildNoChangesTestDispatcher() -> HttpClientTestDispatcher {
        return { request in

            if request.isSplitEndpoint() {
                ThreadUtils.delay(seconds: 0.3) // Simulate network
                self.receivedChangeNumber[self.changeHitIndex.getAndAdd(1)] = request
                    .parameters?["since"] as? Int64 ?? 0
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 10000, till: 10000).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {}
            return self.streamingBinding!
        }
    }

    private func getChanges(withIndex index: Int, since: Int, till: Int) -> SplitChange {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(since)
        change?.till = Int64(till)
        let split = change?.splits[0]
        if let partitions = split?.conditions?[2].partitions {
            for (i, partition) in partitions.enumerated() {
                partition.treatment = "on\(i)"
                if index == i {
                    partition.size = 100
                } else {
                    partition.size = 0
                }
            }
        }
        return change!
    }

    private func loadChangesExpired() {
        cachedSplit = TestingHelper.buildSplit(name: splitName, treatment: "boom")
        for i in 0 ..< 5 {
            let change = getChanges(
                withIndex: 0,
                since: numbers[i],
                till: numbers[i])

            changes.append(change)

            let json = (try? Json.encodeToJson(TargetingRulesChange(
                featureFlags: change,
                ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)))) ?? ""
            jsonChanges.insert(json, at: i)
        }
    }

    private func loadChanges() {
        for i in 0 ..< 5 {
            let change = getChanges(
                withIndex: i,
                since: numbers[i],
                till: numbers[i])

            changes.append(change)
            let json = (try? Json.encodeToJson(change)) ?? ""
            jsonChanges.insert(json, at: i)
        }
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = .verbose
        return splitConfig
    }

    override func tearDown() {
        IntegrationCoreDataHelper.stopObservingChanges()
    }
}

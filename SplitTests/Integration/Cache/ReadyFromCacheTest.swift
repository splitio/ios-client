//
//  ReadyFromCacheTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ReadyFromCacheTest: XCTestCase {
    var globalCacheReadyFired: Atomic<Bool>!
    var globalReadyFired : Atomic<Bool>!
    var jsonChanges: [String]!
    var changes: [TargetingRulesChange]!
    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changeHitIndex: AtomicInt!
    var receivedChangeNumber: [Int64]!

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.test)

    override func setUp() {
        receivedChangeNumber = Array(repeating: 0, count: 100)
        globalCacheReadyFired = Atomic(false)
        globalReadyFired = Atomic(false)
        changeHitIndex = AtomicInt(0) // First hit will be with index == 0. Index == 0 if for cache
        changes = [TargetingRulesChange]()
        jsonChanges = [String]()
        loadChanges()
    }

    func testExistingSplitsAndConnectionOk() {
        // When feature flags and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: changes[0].featureFlags.splits[0])
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        var readyFired = false
        var cacheReadyFired = false

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }

        client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
            readyFired = true
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)
        let treatmentCache = client.getTreatment(splitName)

        globalCacheReadyFired.set(true)

        ThreadUtils.delay(seconds: 5)
        wait(for: [readyExp], timeout: 10)
        let treatmentReady = client.getTreatment(splitName)

        XCTAssertTrue(cacheReadyFired)
        XCTAssertTrue(readyFired)
        XCTAssertEqual("on0", treatmentCache)
        XCTAssertEqual("on1", treatmentReady)

        client.destroy()
    }

    func testExistingSplitsAndNoConnection() {
        // When feature flags and connection not available, ready from cache should be fired and Ready should NOT be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: changes[0].featureFlags.splits[0])
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        var readyFired = false
        var cacheReadyFired = false
        var timeoutFired = false

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }

        client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
            readyFired = true
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
            timeoutFired = true
        }

        wait(for: [cacheReadyExp], timeout: 10)
        let treatmentCache = client.getTreatment(splitName)

        ThreadUtils.delay(seconds: 1)
        wait(for: [readyExp], timeout: 10)
        let treatmentReady = client.getTreatment(splitName)

        XCTAssertTrue(cacheReadyFired)
        XCTAssertFalse(readyFired)
        XCTAssertTrue(timeoutFired)
        XCTAssertEqual("on0", treatmentCache)
        XCTAssertEqual("on0", treatmentReady)

        client.destroy()
    }

    func testNotExistingSplitsAndConnectionOk() {
        // When NO feature flags and connection available, ready from cache should be fired alongside Ready
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let readyExp = XCTestExpectation()

        var readyFired = false
        var cacheReadyFired = false
        var timeoutFired = false

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)
        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyFired = true
        }

        client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
            readyFired = true
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
            timeoutFired = true
        }

        ThreadUtils.delay(seconds: 1)
        let treatmentCache = client.getTreatment(splitName)

        globalCacheReadyFired.set(true)

        ThreadUtils.delay(seconds: 1)
        wait(for: [readyExp], timeout: 3)
        let treatmentReady = client.getTreatment(splitName)

        XCTAssertTrue(cacheReadyFired)
        XCTAssertTrue(readyFired)
        XCTAssertFalse(timeoutFired)
        XCTAssertEqual("control", treatmentCache)
        XCTAssertEqual("on1", treatmentReady)

        client.destroy()
    }

    func testSplitsAndConnOk_FromNoSplitFilterToFilter() {
        // When feature flags and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: changes[0].featureFlags.splits[0])
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        var treatmentsCache = [String]()
        var treatmentsReady = [String]()

        for i in 0..<2 {

            let readyExp = XCTestExpectation()
            let cacheReadyExp = XCTestExpectation()

            if i == 1 {
                let syncConfig = SyncConfig.builder()
                    .addSplitFilter(SplitFilter.byName(["workm"]))
                    .build()

                splitConfig.sync = syncConfig
            }


            let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
                .setConfig(splitConfig).build()!

            let client = factory.client

            client.on(event: SplitEvent.sdkReadyFromCache) {
                cacheReadyExp.fulfill()
            }

            client.on(event: SplitEvent.sdkReady) {
                readyExp.fulfill()
            }

            client.on(event: SplitEvent.sdkReadyTimedOut) {
                readyExp.fulfill()
            }

            wait(for: [cacheReadyExp], timeout: 10)
            treatmentsCache.insert(client.getTreatment(splitName), at: i)

            globalCacheReadyFired.set(true)

            ThreadUtils.delay(seconds: 2)
            wait(for: [readyExp], timeout: 10)
            treatmentsReady.insert(client.getTreatment(splitName), at: i)

            globalCacheReadyFired.set(false)
            client.destroy()
            ThreadUtils.delay(seconds: 2)
        }

        XCTAssertEqual("on0", treatmentsCache[0])
        XCTAssertEqual("on1", treatmentsReady[0])
        XCTAssertEqual("on1", treatmentsCache[1])
        XCTAssertEqual("on2", treatmentsReady[1])

        XCTAssertEqual(100, receivedChangeNumber[1])
        XCTAssertEqual(1000, receivedChangeNumber[2])

    }

    func testSplitsAndConnOk_FromSplitFilterToNoFilter() {
        // When feature flags and connection available, ready from cache and Ready should be fired
        changes = [TargetingRulesChange]()
        jsonChanges = [String]()
        loadChanges1()
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let split =  changes[0].featureFlags.splits[0]
        let split1Name = "split1"
        let split1Treatment = "t1"
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100) // querytrings changes so change# from 100 to -1
        let split1 = buildSplit(name: split1Name, treatment: split1Treatment)
        splitDatabase.splitDao.syncInsertOrUpdate(split: split)
        splitDatabase.splitDao.syncInsertOrUpdate(split: split1)


        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

        var treatmentsCache = [Int: String]()
        var treatmentsReady = [Int: String]()
        var treatments1Cache = [Int: String]()
        var treatments1Ready = [Int: String]()

        for i in 0..<2 {
            let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
            let builder = DefaultSplitFactoryBuilder()
            _ = builder.setHttpClient(httpClient)
            _ = builder.setReachabilityChecker(ReachabilityMock())
            _ = builder.setTestDatabase(splitDatabase)
            let readyExp = XCTestExpectation()
            let cacheReadyExp = XCTestExpectation()

            if i == 0 {
                let syncConfig = SyncConfig.builder()
                    .addSplitFilter(SplitFilter.byName(["workm"]))
                    .build()

                splitConfig.sync = syncConfig
            }

            let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
                .setConfig(splitConfig).build()!

            let client = factory.client

            client.on(event: SplitEvent.sdkReadyFromCache) {
                cacheReadyExp.fulfill()
            }

            client.on(event: SplitEvent.sdkReady) {
                readyExp.fulfill()
            }

            client.on(event: SplitEvent.sdkReadyTimedOut) {
                readyExp.fulfill()
            }

            wait(for: [cacheReadyExp], timeout: 10)
            treatmentsCache[i] = client.getTreatment(splitName)
            treatments1Cache[i] = client.getTreatment(split1Name)

            globalCacheReadyFired.set(true)

            ThreadUtils.delay(seconds: 2)
            wait(for: [readyExp], timeout: 10)
            treatmentsReady[i] = client.getTreatment(splitName)
            treatments1Ready[i] = client.getTreatment(split1Name)

            globalCacheReadyFired.set(false)
            client.destroy()
            ThreadUtils.delay(seconds: 2)
        }

        XCTAssertEqual("on0", treatmentsCache[0])
        XCTAssertEqual("on1", treatmentsReady[0])
        XCTAssertEqual("on1", treatmentsCache[1])
        XCTAssertEqual("on2", treatmentsReady[1])

        XCTAssertEqual("control", treatments1Cache[0])
        XCTAssertEqual("control", treatments1Ready[0])
        XCTAssertEqual("control", treatments1Cache[1])
        XCTAssertEqual("t1", treatments1Ready[1])

        XCTAssertEqual(-1, receivedChangeNumber[1])
        XCTAssertEqual(1000, receivedChangeNumber[2])

    }

    func testPersistentAttributesEnabled() {
        persistentAttributes(enabled: true, treatment: "ta1")
    }

    func testPersistentAttributesDisabled() {
        persistentAttributes(enabled: false, treatment: "on")
    }

    func testLargeSegmentsEnabled() {
        persistentAttributes(enabled: true, treatment: "ta1", largeSegmentsEnabled: true)
    }

    func persistentAttributes(enabled: Bool, treatment: String, largeSegmentsEnabled: Bool = false) {
        loadChangesAttr()
        let userKey = "otherKey"
        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test", queue: dbqueue)
        let split1 =  changes[5].featureFlags.splits[1]
        splitDatabase.attributesDao.syncUpdate(userKey: userKey, attributes: ["isEnabled": true])
        splitDatabase.splitDao.syncInsertOrUpdate(split: split1)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = enabled

        let readyExp = XCTestExpectation()
        let cacheReadyExp = XCTestExpectation()

        var readyFired = false
        var cacheReadyFired = false

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }

        client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
            readyFired = true
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            readyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)
        let treatmentCache = client.getTreatment("split1")

        globalCacheReadyFired.set(true)

        ThreadUtils.delay(seconds: 5)
        wait(for: [readyExp], timeout: 10)

        XCTAssertTrue(cacheReadyFired)
        XCTAssertTrue(readyFired)
        XCTAssertEqual(treatment, treatmentCache)

        client.destroy()
    }

    private func getChanges(for hitNumber: Int) -> Data {
        if hitNumber < jsonChanges.count {
            return Data(self.jsonChanges[hitNumber].utf8)
        }
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        self.changeHitIndex.set(1)
        return { request in
            if request.isSplitEndpoint() {
                if self.globalCacheReadyFired.value {
                    let changesIndex = self.changeHitIndex.getAndAdd(1)
                    self.receivedChangeNumber[changesIndex] = request.parameters?["since"] as? Int64 ?? 0
                    return TestDispatcherResponse(code: 200, data: self.getChanges(for: changesIndex))
                }
                return TestDispatcherResponse(code: 500, data: self.getChanges(for: 99999))
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
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            }
            return self.streamingBinding!
        }
    }

    private func getChanges(withIndex index: Int, since: Int, till: Int) -> TargetingRulesChange {
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
        return TargetingRulesChange(featureFlags: change!, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))
    }

    private func buildSplit(name: String, treatment: String) -> Split {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(1)
        change?.till = Int64(1)
        let split = change!.splits[0]
        split.name = name
        if let partitions = split.conditions?[2].partitions {
            for (i, partition) in partitions.enumerated() {
                if 1 == i {
                    partition.treatment = treatment
                    partition.size = 100
                } else {
                    partition.treatment = "off"
                    partition.size = 0
                }
            }
        }
        return split
    }

    private func buildSplitWithAttrEval(name: String, treatment: String) -> Split {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(1)
        change?.till = Int64(1)
        let split = change!.splits[0]
        split.name = name

        let condition = split.conditions![2]

        condition.conditionType = .rollout
        let matcher = Matcher()
        matcher.matcherType = .equalToBoolean
        matcher.booleanMatcherData = true
        let keySelector = KeySelector()
        keySelector.attribute = "isEnabled"
        matcher.keySelector = keySelector
        let matcherGroup = MatcherGroup()
        matcherGroup.matcherCombiner = .and
        matcherGroup.matchers = [matcher]
        condition.matcherGroup = matcherGroup
        split.conditions![0] = condition

        if let partitions = split.conditions?[0].partitions {
            for (i, partition) in partitions.enumerated() {
                if 1 == i {
                    partition.treatment = treatment
                    partition.size = 100
                } else {
                    partition.treatment = "off"
                    partition.size = 0
                }
            }
        }
        return split
    }

    private func loadChanges() {
        for i in 0..<5 {
            let change = getChanges(withIndex: i,
                                    since: numbers[i],
                                    till: numbers[i])

            changes.append(change)
            let json =  (try? Json.encodeToJson(change)) ?? ""
            jsonChanges.insert(json, at: i)
        }
    }

    private func loadChanges1() {
        for i in 0..<5 {
            let change = getChanges(withIndex: i,
                                    since: numbers[i],
                                    till: numbers[i])

            if i==2 {
                change.featureFlags.splits.append(buildSplit(name: "split1", treatment: "t1"))
            }
            changes.append(change)
            let json =  (try? Json.encodeToJson(change)) ?? ""
            jsonChanges.insert(json, at: i)
        }
    }

    private func loadChangesAttr() {
        for i in 0..<5 {
            let change = getChanges(withIndex: i,
                                    since: numbers[i],
                                    till: numbers[i])

            if i==0 {
                change.featureFlags.splits.append(buildSplitWithAttrEval(name: "split1", treatment: "ta1"))
            }
            changes.append(change)
            let json =  (try? Json.encodeToJson(change)) ?? ""
            jsonChanges.insert(json, at: i)
        }
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = .verbose
        return splitConfig
    }
    
}


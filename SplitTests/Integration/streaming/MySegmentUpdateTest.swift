//
//  MySegmentUpdateTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class MySegmentUpdateTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    let sseMExp = XCTestExpectation(description: "Sse conn M")
    var notificationTemplate: String!
    let kDataField = "[NOTIFICATION_DATA]"
    var msHit = 0

    let kRefreshRate = 1

    var mySegExp: XCTestExpectation!

    var testFactory: TestSplitFactory!
    var queue = DispatchQueue(label: "pepe")

    override func setUp() {
        hitCountByKey = [String: Int]()
        loadNotificationTemplate()
    }

    func testMyLargeSegmentsUpdate() throws {
        try mySegmentsUpdateTest(type: .myLargeSegmentsUpdate)
    }

    func testMySegmentsUpdate() throws {
        try mySegmentsUpdateTest(type: .mySegmentsUpdate)
    }

    func mySegmentsUpdateTest(type: NotificationType) throws {
        let userKey = "key1"
        testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        mySegExp = XCTestExpectation()
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client
        let db = testFactory.splitDatabase

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp], timeout: 50)

        streamingBinding?.push(message: ":keepalive")

        wait(for: [mySegExp], timeout: 5)

        // Unbounded fetch notification should trigger my segments
        // refresh on synchronizer
        // Set count to 0 to start counting hits
        syncSpy.forceMySegmentsCalledCount = 0
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.unboundedNotification(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp], timeout: 5)

        // Should not trigger any fetch to my segments because
        // this payload doesn't have "key1" enabled

        Thread.sleep(forTimeInterval: 0.5)
        pushMessage(TestingData.escapedBoundedNotificationZlib(type: type, cn: mySegmentsCns[cnIndex()]))

        // Pushed key list message. Key 1 should add a segment
        sdkUpdExp = XCTestExpectation()

        Thread.sleep(forTimeInterval: 0.5)
        pushMessage(TestingData.escapedKeyListNotificationGzip(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp], timeout: 5)

        sdkUpdExp = XCTestExpectation()
        Thread.sleep(forTimeInterval: 0.5)
        pushMessage(TestingData.segmentRemovalNotification(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp], timeout: 5)

        Thread.sleep(forTimeInterval: 2.0)
        var segmentEntity: [String]!
        if type == .mySegmentsUpdate {
            segmentEntity = db.mySegmentsDao.getBy(userKey: testFactory.userKey)?.segments.map { $0.name } ?? []
        } else {
            segmentEntity = db.myLargeSegmentsDao.getBy(userKey: testFactory.userKey)?.segments.map { $0.name } ?? []
        }

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(1, syncSpy.forceMySegmentsSyncCount[userKey] ?? 0)
        XCTAssertEqual(1, segmentEntity.filter { $0 == "new_segment_added" }.count)
        XCTAssertEqual(0, segmentEntity.filter { $0 == "segment1" }.count)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }
    
    func testSdkReadyWaitsForSegments() throws {
        
        var sdkReadyFired = false
        let userKey = "test-user-key"
        
        let sdkReady = XCTestExpectation(description: "SDK should be ready")
        let segmentsHit = XCTestExpectation(description: "/memberships should be hit at least once")
        let membershipsHit = XCTestExpectation(description: "/memberships should be hit multiple times")
        
        //MARK: Key part
        membershipsHit.expectedFulfillmentCount = 4

        // 1. Configure dispatcher
        let dispatcher: HttpClientTestDispatcher = { request in
            if request.url.absoluteString.contains("/splitChanges") {
                let json = IntegrationHelper.loadSplitChangeFileJson(name: "splitchanges_1", sourceClass: IntegrationHelper()) // send splitChanges with Segments
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.url.absoluteString.contains("/memberships") {
                segmentsHit.fulfill()
                membershipsHit.fulfill()
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            return TestDispatcherResponse(code: 200)
        }

        // 2. Setup Factory, Network & Client
        let testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: dispatcher, streamingHandler: buildStreamingHandler())
        try testFactory.buildSdk(polling: true)
        let client = testFactory.client

        client.on(event: .sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [segmentsHit], timeout: 3)
        XCTAssertEqual(sdkReadyFired, false)
        
        // 3. Test
        wait(for: [sdkReady, membershipsHit], timeout: 20)
        
        // Cleanup
        destroy(client)
    }
    
    func testSdkAvoidsMembershipsIfNoSegmentsAreUsed() throws {
        
        var sdkReadyFired = false
        let userKey = "test-user-key"
        
        let sdkReady = XCTestExpectation(description: "SDK should be ready")
        let segmentsHit = XCTestExpectation(description: "/memberships should be hit at least once")
        var membershipsHit = 0

        // 1. Configure dispatcher
        let dispatcher: HttpClientTestDispatcher = { request in
            if request.url.absoluteString.contains("/splitChanges") {
                let json = IntegrationHelper.loadSplitChangeFileJson(name: "splitschanges_no_segments", sourceClass: IntegrationHelper()) // send splitChanges wtihout Segments
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.url.absoluteString.contains("/memberships") {
                segmentsHit.fulfill()
                membershipsHit += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            
            return TestDispatcherResponse(code: 200)
        }

        // 2. Setup Factory, Network & Client
        let testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: dispatcher, streamingHandler: buildStreamingHandler())
        try testFactory.buildSdk(polling: true)
        let client = testFactory.client

        client.on(event: .sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [segmentsHit], timeout: 3)
        XCTAssertEqual(sdkReadyFired, false)
        
        // Inverted expectation
        let waitExp = XCTestExpectation(description: "Just waiting")
        waitExp.isInverted = true
        wait(for: [waitExp], timeout: 15)
        
        // MARK: Key part
        XCTAssertEqual(membershipsHit, 1, "After 15 seconds it should hit /memberships just once")
        
        // Cleanup
        destroy(client)
    }
    
    func testSdkAvoidsMembershipsIfNoSegmentsAreUsedFromCache() throws {
        
        var sdkReadyFired = false
        var cacheReadyFired = true
        let sdkReady = XCTestExpectation(description: "SDK should be ready")
        let cacheReadyExp = XCTestExpectation(description: "Cache should be ready")
        let segmentsHit = XCTestExpectation(description: "/memberships should be hit at least once")
        var membershipsHit = 0

        // 1. Configure dispatcher
        let dispatcher: HttpClientTestDispatcher = { request in
            if request.url.absoluteString.contains("/splitChanges") {
                let json = IntegrationHelper.loadSplitChangeFileJson(name: "splitschanges_no_segments", sourceClass: IntegrationHelper()) // send splitChanges wtihout Segments
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.url.absoluteString.contains("/memberships") {
                segmentsHit.fulfill()
                membershipsHit += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            
            return TestDispatcherResponse(code: 200)
        }

        // 2. Setup Factory, Network & Client
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 1
        splitConfig.segmentsRefreshRate = 1
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.streamingEnabled = false
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 999999
        splitConfig.eventsFirstPushWindow = 999
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: "localhost").set(eventsEndpoint: "localhost").build()
        
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test")
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: "1.3")
        let savedSplit = SplitTestHelper.newSplitWithMatcherType("splits_segments", .allKeys)
        splitDatabase.splitDao.syncInsertOrUpdate(split: savedSplit)
        
        let userKey = "test-user-key"
        let key: Key = Key(matchingKey: userKey, bucketingKey: nil)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher, streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let builder = DefaultSplitFactoryBuilder()
        
        _ = builder.setTestDatabase(splitDatabase)
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory?.client
        
        client?.on(event: .sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        client?.on(event: .sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }
        
        wait(for: [segmentsHit], timeout: 3)
        XCTAssertEqual(sdkReadyFired, false)
        
        wait(for: [cacheReadyExp, sdkReady], timeout: 3)
        
        // MARK: Key part
        let waitExp = XCTestExpectation(description: "Just waiting")
        waitExp.isInverted = true // Inverted expectation
        wait(for: [waitExp], timeout: 10)
        
        XCTAssertEqual(membershipsHit, 1, "After 15 seconds it should hit /memberships just once")
        
        // Cleanup
        if let client = client {
            destroy(client)
        }
    }
    
    func testSdkHitsMembershipsIfSegmentsAreUsedFromCache() throws {
        
        var sdkReadyFired = false
        var cacheReadyFired = true
        let sdkReady = XCTestExpectation(description: "SDK should be ready")
        let cacheReadyExp = XCTestExpectation(description: "Cache should be ready")
        let segmentsHit = XCTestExpectation(description: "/memberships should be hit at least once")
        var membershipsHit = 0

        // 1. Configure dispatcher
        let dispatcher: HttpClientTestDispatcher = { request in
            if request.url.absoluteString.contains("/splitChanges") {
                let json = IntegrationHelper.loadSplitChangeFileJson(name: "splitschanges_no_segments", sourceClass: IntegrationHelper()) // splitChanges wtih no Segments
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.url.absoluteString.contains("/memberships") {
                segmentsHit.fulfill()
                membershipsHit += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            
            return TestDispatcherResponse(code: 200)
        }

        // 2. Setup Factory, Network & Client
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 1
        splitConfig.segmentsRefreshRate = 1
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.streamingEnabled = false
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 999999
        splitConfig.eventsFirstPushWindow = 999
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: "localhost").set(eventsEndpoint: "localhost").build()
        
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test")
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: "1.3")
        splitDatabase.generalInfoDao.update(info: .segmentsInUse, longValue: 1)
        let savedSplit = SplitTestHelper.newSplitWithMatcherType("splits_segments", .inSegment)
        splitDatabase.splitDao.syncInsertOrUpdate(split: savedSplit)
        
        let userKey = "test-user-key"
        let key: Key = Key(matchingKey: userKey, bucketingKey: nil)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher, streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let builder = DefaultSplitFactoryBuilder()
        
        _ = builder.setTestDatabase(splitDatabase)
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory?.client
        
        client?.on(event: .sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        client?.on(event: .sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }
        
        wait(for: [segmentsHit, cacheReadyExp, sdkReady], timeout: 4)
        
        // MARK: Key part
        let waitExp = XCTestExpectation(description: "Just waiting")
        waitExp.isInverted = true // Inverted expectation
        wait(for: [waitExp], timeout: 10)
        
        XCTAssertGreaterThan(membershipsHit, 2, "After 15 seconds, if segments are used, SDK should hit /memberships many times")
        
        // Cleanup
        if let client = client {
            destroy(client)
        }
    }
    
    func testSdkRestartMembershipsSyncIfNewFlag() throws {
        
        var sdkReadyFired = false
        var cacheReadyFired = true
        let sdkReady = XCTestExpectation(description: "SDK should be ready")
        let cacheReadyExp = XCTestExpectation(description: "Cache should be ready")
        let segmentsHit = XCTestExpectation(description: "/memberships should be hit at least once")
        var membershipsHit = 0
        
        var json = IntegrationHelper.loadSplitChangeFileJson(name: "splitschanges_no_segments", sourceClass: IntegrationHelper()) // no Segments

        // 1. Configure dispatcher
        let dispatcher: HttpClientTestDispatcher = { request in
            if request.url.absoluteString.contains("/splitChanges") {
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.url.absoluteString.contains("/memberships") {
                segmentsHit.fulfill()
                membershipsHit += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            
            return TestDispatcherResponse(code: 200)
        }

        // 2. Setup Factory, Network & Client
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 2
        splitConfig.segmentsRefreshRate = 2
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.streamingEnabled = false
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 999999
        splitConfig.eventsFirstPushWindow = 999
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: "localhost").set(eventsEndpoint: "localhost").build()
        
        let splitDatabase = TestingHelper.createTestDatabase(name: "ready_from_cache_test")
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: "1.3")
        
        let userKey = "test-user-key"
        let key: Key = Key(matchingKey: userKey, bucketingKey: nil)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher, streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let builder = DefaultSplitFactoryBuilder()
        
        _ = builder.setTestDatabase(splitDatabase)
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory?.client
        
        client?.on(event: .sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        client?.on(event: .sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            cacheReadyFired = true
        }
        
        wait(for: [segmentsHit], timeout: 3)
        XCTAssertEqual(sdkReadyFired, false)
        
        wait(for: [cacheReadyExp, sdkReady], timeout: 4)
        
        // MARK: Key part
        var waitExp = XCTestExpectation(description: "Just waiting")
        waitExp.isInverted = true // Inverted expectation
        wait(for: [waitExp], timeout: 10)
        XCTAssertEqual(membershipsHit, 1, "After some time, if segments are not used, SDK shouldn't hit /memberships")
        
        // MARK: Key part 2
        json = IntegrationHelper.loadSplitChangeFileJson(name: "splitchanges_1", sourceClass: IntegrationHelper()) // splitChanges, now WITH Segments
        
        waitExp = XCTestExpectation(description: "Just waiting")
        waitExp.isInverted = true // Inverted expectation
        wait(for: [waitExp], timeout: 15)
        XCTAssertGreaterThan(membershipsHit, 2, "If new flags with segments arrive, the mechanism should be restarted and SDK should hit /memberships many times again")
        
        // Cleanup
        if let client = client {
            destroy(client)
        }
    }

    func testMySegmentsUpdateBounded() throws {
        try mySegmentsUpdateBoundedTest(type: .mySegmentsUpdate)
    }

    func testMySegmentsLargeUpdateBounded() throws {
        try mySegmentsUpdateBoundedTest(type: .myLargeSegmentsUpdate)
    }

    func mySegmentsUpdateBoundedTest(type: NotificationType) throws {
        mySegExp = XCTestExpectation()
        let userKey = "603516ce-1243-400b-b919-0dce5d8aecfd"
        testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Adding multi client
        let sdkReadyMExp = XCTestExpectation(description: "SDK READY Expectation mcli")
        var sdkUpdMExp = XCTestExpectation(description: "SDK UPDATE Expectation mcli")
        let userKeyM = "09025e90-d396-433a-9292-acef23cf0ad1"
        let mClient = testFactory!.client(matchingKey: userKeyM)

        mClient.on(event: SplitEvent.sdkReady) {
            sdkReadyMExp.fulfill()
        }

        mClient.on(event: SplitEvent.sdkUpdated) {
            sdkUpdMExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sdkReadyMExp, sseExp, sseMExp], timeout: 15)

        streamingBinding?.push(message: ":keepalive")

        wait(for: [mySegExp], timeout: 5)

        // Unbounded fetch notification should trigger my segments
        // refresh on synchronizer
        // Set count to 0 to start counting hits
        syncSpy.forceMySegmentsCalledCount = 0
        sdkUpdExp = XCTestExpectation()
        sdkUpdMExp = XCTestExpectation()
        pushMessage(TestingData.unboundedNotification(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp, sdkUpdMExp], timeout: 5)


        // Pushed key list message. Key 1 should add a segment
        sdkUpdExp = XCTestExpectation()
        sdkUpdMExp = XCTestExpectation()
        pushMessage(TestingData.escapedBoundedNotificationGzip(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp, sdkUpdMExp], timeout: 15)

        sdkUpdExp = XCTestExpectation()
        sdkUpdMExp = XCTestExpectation()
        pushMessage(TestingData.escapedBoundedNotificationZlib(type: type, cn: mySegmentsCns[cnIndex()]))
        wait(for: [sdkUpdExp, sdkUpdMExp], timeout: 15)

        // Should trigger unbounded
        sdkUpdExp = XCTestExpectation()
        sdkUpdMExp = XCTestExpectation()
        pushMessage(TestingData.escapedBoundedNotificationMalformed(type: type, cn: mySegmentsCns[cnIndex()]))

        wait(for: [sdkUpdExp, sdkUpdMExp], timeout: 15)


        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(4, syncSpy.forceMySegmentsSyncCount[userKey] ?? 0)
        XCTAssertEqual(4, syncSpy.forceMySegmentsSyncCount[userKeyM] ?? 0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    var segUboundFetchExp: XCTestExpectation?
    func testSeveralNotificationAndOneFetch() throws {
        mySegExp = XCTestExpectation()
        let userKey = IntegrationHelper.dummyUserKey
        testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp, sseMExp], timeout: 15)

        streamingBinding?.push(message: ":keepalive")

        wait(for: [mySegExp], timeout: 5)

        // Unbounded fetch notification should trigger my segments
        // refresh on synchronizer
        // Set count to 0 to start counting hits
        syncSpy.forceMySegmentsSyncCount[userKey] = 0
        sdkUpdExp = XCTestExpectation()

        let cn = mySegmentsCns[cnIndex()]
        let count = 10
        let msHitBefore = msHit
        segUboundFetchExp = XCTestExpectation()
        pushMessage(TestingData.delayedUnboundedNotification(type: .myLargeSegmentsUpdate, cn: cn, delay: 2900))
        for i in 1..<count {
            pushMessage(TestingData.delayedUnboundedNotification(type: .myLargeSegmentsUpdate, cn: cn + i, delay: 500))
        }

        wait(for: [sdkUpdExp, segUboundFetchExp!], timeout: 15)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(count, syncSpy.forceMySegmentsSyncCount[userKey] ?? 0)
        XCTAssertEqual(msHitBefore + 1, msHit)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    var mySegmentsCns = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400]
    var hitCountByKey: [String: Int]!

    func cnIndex() -> Int {
        let mySegmentsHitCount = (hitCountByKey.values.max() ?? 1) + 1
        return min(mySegmentsHitCount, mySegmentsCns.count - 1)
    }

    func nextHitCount(key: String) -> Int {
        queue.sync {
            hitCountByKey[key] = (hitCountByKey[key] ?? 0) + 1
            let hit = hitCountByKey[key] ?? 0
            print("SEGMENT HIT: \(hit)")
            return hit
        }
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }

            if request.isMySegmentsEndpoint() {
                let hit = self.nextHitCount(key: request.url.lastPathComponent)
                self.msHit = self.msHit + 1
                if self.msHit == 2 {
                    self.mySegExp.fulfill()
                }
                self.segUboundFetchExp?.fulfill()
                return self.createResponse(code: 200, json: self.updatedSegments(index: hit))
            }

            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func createResponse(code: Int, json: String) -> TestDispatcherResponse {
        return TestDispatcherResponse(code: 200, data: Data(json.utf8))
    }

    private func updatedSegments(index: Int) -> String {
        var resp = [String]()
        let cn = mySegmentsCns[min(index, mySegmentsCns.count - 1)]
        for i in (1..<index) {
            let seg = "{ \"n\":\"segment\(i)\"}"
            resp.append(seg)
        }
        let segs = resp.joined(separator: ",")
        let json = "{\"ms\":{\"k\": [\(segs)]}, \"ls\": {\"cn\": \(cn), \"k\": [\(segs)]}}"
        print("-----")
        print(json)
        return json
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            self.sseMExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func wait() {
        ThreadUtils.delay(seconds: Double(self.kRefreshRate) * 2.0)
    }

    private func loadNotificationTemplate() {
        if let template = FileHelper.readDataFromFile(sourceClass: self, name: "push_msg-segment_updV2", type: "txt") {
            notificationTemplate = template
        }
    }

    private func pushMessage(_ text: String) {
        var msg = text.replacingOccurrences(of: "\n", with: " ")
        msg = notificationTemplate.replacingOccurrences(of: kDataField, with: msg)
        streamingBinding?.push(message: msg)
    }
    
    fileprivate func destroy(_ client: SplitClient) {
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy {
            semaphore.signal()
        }
        semaphore.wait()
    }
}

//  Created by Martin Cardozo on 22/01/2026

import Foundation
import XCTest
@testable import Split

class MetadataEventsTests: XCTestCase, @unchecked Sendable {
    
    // For all tests
    var exp0: XCTestExpectation? = nil
    var exp1: XCTestExpectation? = nil
    var exp2: XCTestExpectation? = nil
    var exp3: XCTestExpectation? = nil
    
    // SDK components
    var factory: SplitFactory? = nil
    var client: SplitClient? = nil
    var listener: TestEventListener? = nil
    
    // Streaming
    var sseConnHits = 0
    var streamingBinding: TestStreamResponseBinding?
    var sseExp: XCTestExpectation!
    var treatments = ["on", "on", "free", "conta", "off"]
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changes = [String]()
    var splitsChangesHits = 0
    var reqChangesIndex = 0
    let kChangeNbInterval: Int64 = 86400
    var impHit: [ImpressionsTest]?
    let impExp = XCTestExpectation(description: "impressions")
    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]
    var isSseAuthHit = false
    var isSseHit = false
    var checkSplitChangesHit = false
    var checkMySegmentsHit = false
    var mySegExp: XCTestExpectation!
    var splitsChangesExp: XCTestExpectation!
    var mySegmentsHits = 0
    
    override func setUp() {
        
        isSseAuthHit = false
        isSseHit = false
        mySegmentsHits = 0
        
        // Normal ready
        exp0 = XCTestExpectation(description: "SDK READY")

        // Events With Metadata
        exp1 = XCTestExpectation(description: "SDK READY METADATA")
        exp1!.assertForOverFulfill = true  // Fail if fulfilled more than once (useful for some tests)
        exp2 = XCTestExpectation(description: "SDK READY FROM CACHE METADATA")
        exp2!.assertForOverFulfill = true
        exp3 = XCTestExpectation(description: "SDK UPDATED METADATA")
        exp3!.assertForOverFulfill = true
        
        // Setup
        factory = IntegrationHelper().simplestFactoryWithDummyKeys().build()
        client = factory?.client
        
        // Listener
        listener = TestEventListener(readyExp: exp1!, fromCacheExp: exp2!, updateExp: exp3!, listenerNumber: 1)
        client?.addEventListener(listener: listener!)
        
        client?.on(event: .sdkReady) {
            print("SDK Ready")
            self.exp0!.fulfill()
        }
        
        wait(for: [exp0!, exp1!], timeout: 5)
    }

    override func tearDown() {
        exp0 = nil
        exp1 = nil
        exp2 = nil
        exp3 = nil
    }
    
    func testEventReplay() {
        // IMPORTANT: This test has the expectation inverted since the current (old) events manager does not allow ready replay.
        // When the new events engine is implemented this should fail. Flip it to normal expectation and it should pass.
        
        let replayExp = XCTestExpectation(description: "SDK READY SHOULD REPLAY INMEDIATELY TO NEW SUBS")
        replayExp.isInverted = true
        
        let listener2 = TestEventListener(readyExp: replayExp, fromCacheExp: exp2!, updateExp: exp3!, listenerNumber: 2)
        client?.addEventListener(listener: listener2)
        
        wait(for: [replayExp], timeout: 3)
    }
    
    func testReadyMetadataFresh() {
        XCTAssertEqual(listener?.readyMetadata?.isInitialCacheLoad, true)
        XCTAssertEqual(listener?.readyMetadata?.lastUpdateTimestamp, nil)
        
        XCTAssertEqual(listener?.fromCacheMetadata?.isInitialCacheLoad, true)
        XCTAssertEqual(listener?.fromCacheMetadata?.lastUpdateTimestamp, nil)
    }
    
    func testReadyMetadataReRun() throws {
        
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        let metadataReady = XCTestExpectation(description: "SDK READY FROM CACHE")
        
        let testFactory = TestSplitFactory(userKey: IntegrationHelper.dummyUserKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcherEmpty(), streamingHandler: buildStreamingHandler())
        
        // MARK: Key part (re-run simulation)
        try testFactory.buildSdk(splitsUpdateTimeStamp: 100)
        
        let client = testFactory.client

        // Listener
        let listener = TestEventListener(readyExp: metadataReady)
        client.addEventListener(listener: listener)

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, metadataReady], timeout: 5)
        
        XCTAssertEqual(listener.readyMetadata?.isInitialCacheLoad, false)
        XCTAssertNotNil(listener.readyMetadata?.lastUpdateTimestamp)
    }
    
    func testUpdateMetadataStreaming() {
        
        let apiKey = IntegrationHelper.dummyApiKey
        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdate = XCTestExpectation(description: "SDK Update Expectation")
        
        let database = TestingHelper.createTestDatabase(name: "GralIntegrationTest")
        splitsChangesHits = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcherStreaming(), streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
        
        database.generalInfoDao.update(info: .splitsChangeNumber, longValue: 500)
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999999
        splitConfig.segmentsRefreshRate = 9999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999

        sseExp = XCTestExpectation()
        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!
        
        let client = factory.client
        
        // MARK: Key part 1
        let exp = XCTestExpectation(description: "Update exp")
        let listener = TestEventListener(updateExp: exp)
        client.addEventListener(listener: listener)
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReady.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdate.fulfill()
        }

        wait(for: [sdkReady, sseExp], timeout: 5)
        streamingBinding?.push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok

        streamingBinding?.push(message: StreamingIntegrationHelper.splitUpdateMessage(timestamp: 1999999, changeNumber: 99999))
        
        wait(for: [sdkUpdate, exp], timeout: 5)
        
        // MARK: Key part 2
        XCTAssertEqual(listener.updateMetadata?.type, .flagsUpdate)
        XCTAssertEqual(listener.updateMetadata?.names, ["workm"])

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }
    
    func testUpdateMetadataPolling() throws {
        
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        
        let apiKey = IntegrationHelper.dummyApiKey
        let trafficType = "client"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        let sdkUpdate = XCTestExpectation(description: "SDK Update Expectation")

        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 2
        splitConfig.featuresRefreshRate = 2
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        
        // MARK: Key part 1
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: "localhost").set(eventsEndpoint: "localhost").build()

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory!.client
        
        // MARK: Key part 2
        let exp = XCTestExpectation(description: "Update exp")
        let listener = TestEventListener(updateExp: exp)
        client.addEventListener(listener: listener)
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReady.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdate.fulfill()
        }

        wait(for: [sdkReady, sdkUpdate, exp], timeout: 30)
        
        // MARK: Key part 3
        XCTAssertEqual(listener.updateMetadata?.type, .flagsUpdate)
        XCTAssertEqual(listener.updateMetadata?.names, ["test_feature"])

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }
}

// MARK: Test Event Listener
final class TestEventListener: SplitEventListener {
    
    private let readyExp: XCTestExpectation
    private let fromCacheExp: XCTestExpectation
    private let updateExp: XCTestExpectation
    private let listenerNumber: Int
    
    nonisolated(unsafe) var readyMetadata: SdkReadyMetadata? = nil
    nonisolated(unsafe) var fromCacheMetadata: SdkReadyFromCacheMetadata? = nil
    nonisolated(unsafe) var updateMetadata: SdkUpdateMetadata? = nil
    
    // Parameters are optional to test different handlers at a time
    init(readyExp: XCTestExpectation? = XCTestExpectation(description: "READY METADATA"),
         fromCacheExp: XCTestExpectation? = XCTestExpectation(description: "FROM CACHE METADATA"),
         updateExp: XCTestExpectation? = XCTestExpectation(description: "UPDATE METADATA"),
         listenerNumber: Int? = 0) {
        self.readyExp = readyExp!
        self.fromCacheExp = fromCacheExp!
        self.updateExp = updateExp!
        self.listenerNumber = listenerNumber!
    }
    
    func onReady(_ metadata: SdkReadyMetadata) {
        readyMetadata = metadata
        readyExp.fulfill()
        print("Ready expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
    
    func onReadyFromCache(_ metadata: SdkReadyFromCacheMetadata) {
        fromCacheMetadata = metadata
        fromCacheExp.fulfill()
        print("Ready from Cache expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
    
    func onUpdate(_ metadata: SdkUpdateMetadata) {
        updateMetadata = metadata
        updateExp.fulfill()
        print("Update expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
}


// MARK: Helpers
extension MetadataEventsTests {
    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        let respData = responseSplitChanges()
        var responses = [TestDispatcherResponse]()
        for data in respData {
            let rData = TargetingRulesChange(featureFlags: data, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))
            responses.append(TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(rData).utf8)))
        }

        return { request in
            if request.isSplitEndpoint() {
                let index = self.getAndIncrement()
                if index < self.spExp.count {
                    if index > 0 {
                        self.spExp[index - 1].fulfill()
                    }
                    return responses[index]
                } else if index == self.spExp.count {
                    self.spExp[index - 1].fulfill()
                }
                let json = IntegrationHelper.loadSplitChangeFileJson(name: "splitchanges_1", sourceClass: IntegrationHelper())
                return TestDispatcherResponse(code: 200, data: Data(json!.utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.impHit = try? TestUtils.impressionsFromHit(request: request)
                self.impExp.fulfill()
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            return TestDispatcherResponse(code: 200)
        }
    }
    
    private func responseSplitChanges() -> [SplitChange] {
        var changes = [SplitChange]()

        var prevChangeNumber: Int64 = 0
        for i in 0..<4 {
            let c = loadSplitsChangeFile()!
            c.since = c.till
            if prevChangeNumber != 0 {
                c.till = prevChangeNumber  + kChangeNbInterval
                c.since = c.till
            }
            prevChangeNumber = c.till
            let split = c.splits[0]
            let even = ((i + 2) % 2 == 0)
            split.changeNumber = prevChangeNumber
            split.conditions![0].partitions![0].treatment = "on_\(i)"
            split.conditions![0].partitions![0].size = (even ? 100 : 0)
            split.conditions![0].partitions![1].treatment = "off_\(i)"
            split.conditions![0].partitions![1].size = (even ? 0 : 100)
            changes.append(c)
        }
        return changes
    }
    
    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseConnHits+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {
                self.sseExp.fulfill()
            }
            return self.streamingBinding!
        }
    }
    
    private func loadSplitsChangeFile() -> SplitChange? {
        FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_int_test")
    }
    
    private func loadChanges() {
        for i in 0..<5 {
            let change = getChanges(withTreatment: self.treatments[i],
                                    since: self.numbers[i],
                                    till: self.numbers[i])
            changes.insert(change, at: i)
        }
    }

    private func getChanges(withTreatment: String, since: Int, till: Int) -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(since)
        change?.till = Int64(till)
        let split = change?.splits[0]
        if let partitions = split?.conditions?[2].partitions {
            let partition = partitions.filter { $0.treatment == withTreatment }
            partition[0].size = 100

            for partition in partitions where partition.treatment != withTreatment {
                partition.size = 0
            }
        }
        let targetingRulesChange = TargetingRulesChange(featureFlags: change!, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))
        return (try? Json.encodeToJson(targetingRulesChange)) ?? ""
    }
    
    private func getChanges(for hitNumber: Int) -> SplitChange {
        if hitNumber < numbers.count {
            let jsonData = Data(self.changes[hitNumber].utf8)
            return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
        }
        let jsonData = Data(IntegrationHelper.emptySplitChanges(since: 500, till: 500).utf8)
        return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
    }
    
    private func getAndIncrement() -> Int {
        var i = 0;
        DispatchQueue.test.sync {
            i = self.reqChangesIndex
            self.reqChangesIndex+=1
        }
        return i
    }
    
    private func buildTestDispatcherEmpty() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.sseDisabledResponse().utf8))
            }
            return TestDispatcherResponse(code: 200)
        }
    }
    
    private func buildTestDispatcherStreaming() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let hitNumber = self.getAndUpdateHit()
                return TestDispatcherResponse(code: 200, data: try! Json.encodeToJsonData(TargetingRulesChange(featureFlags: self.getChangesStreaming(for: hitNumber), ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))))
            }
            if request.isMySegmentsEndpoint() {
                self.mySegmentsHits+=1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }
    
    private func getChangesStreaming(for hitNumber: Int) -> SplitChange {
        if hitNumber < numbers.count {
            let jsonData = Data(self.changes[hitNumber].utf8)
            return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
        }
        let jsonData = Data(IntegrationHelper.emptySplitChanges(since: 500, till: 500).utf8)
        return try! Json.decodeFrom(json: jsonData, to: TargetingRulesChange.self).featureFlags
    }
    
    private func getAndUpdateHit() -> Int {
        var hitNumber = 0
        DispatchQueue.test.sync {
            hitNumber = self.splitsChangesHits
            self.splitsChangesHits+=1
        }
        return hitNumber
    }
}

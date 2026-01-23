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
    
    override func setUp() {
        
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
    
    func testReadyMetadataReRun() {
        XCTAssertEqual(listener?.readyMetadata?.isInitialCacheLoad, true)
        XCTAssertEqual(listener?.readyMetadata?.lastUpdateTimestamp, nil)
        
        // TODO: run with timestamp on storage
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
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: "localhost").set(eventsEndpoint: "localhost").build()

        let key: Key = Key(matchingKey: IntegrationHelper.dummyUserKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesTest"))
        _ = builder.setHttpClient(httpClient)
        factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory!.client
        
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

        wait(for: [sdkReady, sdkUpdate, exp], timeout: 30)
        
        // MARK: Key part 2
        XCTAssertEqual(listener.updateMetadata?.type, .FLAGS_UPDATE)
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
    
    func onSdkReady(_ metadata: SdkReadyMetadata) {
        readyMetadata = metadata
        readyExp.fulfill()
        print("Ready expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
    
    func onSdkReadyFromCache(_ metadata: SdkReadyFromCacheMetadata) {
        fromCacheMetadata = metadata
        fromCacheExp.fulfill()
        print("Ready from Cache expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
    
    func onSdkUpdate(_ metadata: SdkUpdateMetadata) {
        updateMetadata = metadata
        updateExp.fulfill()
        print("Update expectation \(listenerNumber) - \(String(describing: Unmanaged.passUnretained(readyExp).toOpaque()))")
    }
}


// MARK: Helpers (for update tests)
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
}

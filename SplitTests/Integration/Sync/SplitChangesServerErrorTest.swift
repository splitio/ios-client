//
//  SplitChangesServerErrorTest.swift
//  SplitChangesServerErrorTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitChangesServerErrorTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    let kChangeNbInterval: Int64 = 86400
    var reqChangesIndex = 0
    var lastChangeNumber: Int64 = 0

    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "error 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    var serverUrl = "localhost"

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    
    var httpClient: HttpClient!
    var streamingBinding: TestStreamResponseBinding?

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        let respData = responseSplitChanges()
        var responses = [TestDispatcherResponse]()
        responses.append(TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(
            TargetingRulesChange(featureFlags: respData[0], ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))).utf8)))
        responses.append(TestDispatcherResponse(code: 500))
        responses.append(TestDispatcherResponse(code: 500))
        responses.append(TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(
            TargetingRulesChange(featureFlags: respData[1], ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))).utf8)))


        return { request in
            if request.isSplitEndpoint() {
                let index = self.reqChangesIndex
                if index < self.spExp.count {
                    if self.reqChangesIndex > 0 {
                        self.spExp[index - 1].fulfill()
                    }
                    self.reqChangesIndex += 1
                    return responses[index]
                } else if index == self.spExp.count {
                    self.spExp[index - 1].fulfill()
                }
                let since = Int(self.lastChangeNumber)
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: since, till: since).utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    // MARK: Test
    /// Getting changes from server and test treatments and change number
    func testChangesError() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_f"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.streamingEnabled = false
        splitConfig.featuresRefreshRate = 3
        splitConfig.impressionRefreshRate = kNeverRefreshRate
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.streamingEnabled = false
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "SplitChangesServerErrorTest"))
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [sdkReady], timeout: 10)

        for i in 0..<4 {
            wait(for: [spExp[i]], timeout: 40)
            treatments.append(client.getTreatment("test_feature"))
        }

        XCTAssertTrue(sdkReadyFired)

        XCTAssertEqual("on_0", treatments[0])
        XCTAssertEqual("on_0", treatments[1])
        XCTAssertEqual("on_0", treatments[2])
        XCTAssertEqual("off_1", treatments[3])

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    private func  responseSplitChanges() -> [SplitChange] {
        var changes = [SplitChange]()

        for i in 0..<2 {
            let c = loadSplitsChangeFile()!
            var prevChangeNumber = c.since
            c.since = prevChangeNumber + kChangeNbInterval
            c.till = c.since
            
            prevChangeNumber = c.till
            lastChangeNumber = prevChangeNumber
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

    private func loadSplitsChangeFile() -> SplitChange? {
        return FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_int_test")
    }

    private func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.decodeFrom(json: content, to: [ImpressionsTest].self)
    }
}


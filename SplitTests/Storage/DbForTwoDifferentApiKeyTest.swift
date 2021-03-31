//
//  DbForTwoDifferentApiKeyTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 31/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class DbForDifferentApiKeysTest: XCTestCase {
    var timestamp = 100
    var streamingBinding: TestStreamResponseBinding?

    var httpClient1: HttpClient!
    var factory1: SplitFactory!
    var client1: SplitClient!
    let apiKey1 = UUID().uuidString


    var httpClient2: HttpClient!
    var factory2: SplitFactory!
    var client2: SplitClient!
    let apiKey2 = UUID().uuidString

    let userKey = IntegrationHelper.dummyUserKey

    static let changeNumberBase: Int64 = 1000;
    let changeNumberF1: Int64 = changeNumberBase + 1
    let changeNumberF2: Int64 = changeNumberBase + 2

    var lastChangeNumbers: [Int64] = [0, 0, 0]
    var firstChangeNumbers: [Int64] = [0, 0, 0]

    var splitsChangesExp: XCTestExpectation?

    let sseExp = XCTestExpectation(description: "Sse conn")
    let kPrimaryChannel = "control_pri"
    let kSecondaryChannel = "control_sec"

    var mySegHitCount = 0
    var splitsHitCount = 0

    let kRefreshRate = 1

    var mySegExps = [XCTestExpectation]()

    var mySegExpIndex = 0
    var splitsExpIndex = 0

    var waitForSplitChangesHit = true
    var waitForMySegmentsHit = false

    override func setUp() {
        timestamp = 100
    }

    func initialization() {
        // Factory 1
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.isDebugModeEnabled = true

        let session = HttpSessionMock()
        let reqManager1 = HttpRequestManagerTestDispatcher(dispatcher: buildBasicDispatcher(factoryNumber: 1),
                                                          streamingHandler: buildStreamingHandler())
        httpClient1 = DefaultHttpClient(session: session, requestManager: reqManager1)



        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient1)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        let factory = builder.setApiKey(apiKey1).setKey(key)
            .setConfig(splitConfig).build()!

        let client1 = factory1.client

        var sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client1.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client1.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        let t1Split1 = client1.getTreatment("split1")
        let t1Split2 = client1.getTreatment("split2")

        client1.destroy()

        // Factory 2
        let reqManager2 = HttpRequestManagerTestDispatcher(dispatcher: buildBasicDispatcher(factoryNumber: 1),
                                                          streamingHandler: buildStreamingHandler())
        httpClient2 = DefaultHttpClient(session: session, requestManager: reqManager2)


        let builder2 = DefaultSplitFactoryBuilder()
        _ = builder2.setHttpClient(httpClient2)
        _ = builder2.setReachabilityChecker(ReachabilityMock())
        let factory2 = builder2.setApiKey(apiKey1).setKey(key)
            .setConfig(splitConfig).build()!

        let client2 = factory2.client

        sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client1.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client1.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        let t2Split1 = client1.getTreatment("split1")
        let t2Split2 = client1.getTreatment("split2")

        streamingBinding?.push(message: ":keepalive")
//        waitForHits()
//        wait(for: [mySegExps[mySegExpIndex],  splitsChangesExps[splitsExpIndex]], timeout: 7)
//
//        timestamp+=1000
//        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
//                                                                                               segment: "new_segment"))
//        justWait() // allow to my segments be updated
//        let treatmentPaused = client.getTreatment(splitName)
//
//        timestamp+=1000
//        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
//                                                                                  controlType: "STREAMING_ENABLED"))
//        justWait() // allow polling to stop
//        timestamp+=1000
//
//        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
//                                                                                               segment: "new_segment"))
//        justWait() // allow to my segments be updated
//        let treatmentEnabled = client.getTreatment(splitName)
//
//        timestamp+=1000
//        streamingBinding?.push(message: StreamingIntegrationHelper.controlMessage(timestamp: timestamp,
//                                                                                  controlType: "STREAMING_DISABLED"))
//
//        timestamp+=1000
//        streamingBinding?.push(message: StreamingIntegrationHelper.mySegmentWithPayloadMessage(timestamp: timestamp,
//                                                                                               segment: "new_segment"))
//        waitForHits()
//        wait(for: [mySegExps[mySegExpIndex],  splitsChangesExps[splitsExpIndex]], timeout: 7)
//
//        justWait()

        XCTAssertEqual("on", t1Split1)
        XCTAssertEqual("on", t1Split1)
        XCTAssertEqual("free", t2Split1)
        XCTAssertEqual("on", t2Split1)
    }

    private func testSplitsUpdate(changeNumber: Int64) {
        splitsChangesExp = XCTestExpectation()
        streamingBinding?.push(message: StreamingIntegrationHelper.splitUpdateMessage(timestamp: nextTimestamp(), changeNumber: Int(changeNumber)))
        wait(for: [splitsChangesExp], 4)
    }

    private func buildBasicDispatcher(factoryNumber: Int) -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let respChangeNumber = Self.changeNumberBase + Int64(factoryNumber)
                self.lastChangeNumbers[factoryNumber] = request.parameters?["since"] as? Int64 ?? 0
                self.splitsHitCount+=1
                if self.lastChangeNumbers[factoryNumber] == -1 {
                    self.firstChangeNumbers[factoryNumber] = -1
                    return TestDispatcherResponse(code: 200, data: Data(self.splitChanges(factoryNumber: factoryNumber).utf8))
                }
                if let exp = self.splitsChangesExp {
                    exp.fulfill()
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: Int(respChangeNumber), till: Int(respChangeNumber)).utf8))
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
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func splitChanges(factoryNumber: Int) -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.splits[0].name = "split\(factoryNumber)"
        change?.since = -1
        change?.till = Self.changeNumberBase + Int64(factoryNumber)
        return (try? Json.encodeToJson(change)) ?? IntegrationHelper.emptySplitChanges
    }

    private func nextTimestamp() -> Int {
        timestamp+=1
        return timestamp
    }
}



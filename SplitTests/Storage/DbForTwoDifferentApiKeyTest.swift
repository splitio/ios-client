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

    var sseExp: [XCTestExpectation]!
    var sseExpIndex = 0

    override func setUp() {
        timestamp = 100
    }

    func testInitialization() {
        sseExpIndex = 0
        sseExp = [XCTestExpectation(), XCTestExpectation()]
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
        factory1 = builder.setApiKey(apiKey1).setKey(key)
            .setConfig(splitConfig).build()!

        let client1 = factory1.client

        let sdkReadyExpectation1 = XCTestExpectation(description: "SDK READY Expectation")

        client1.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation1.fulfill()
        }

        client1.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation1.fulfill()
        }

        wait(for: [sdkReadyExpectation1, sseExp[0]], timeout: 5)
        streamingBinding?.push(message: ":keepalive")
        testSplitsUpdate(changeNumber: changeNumberF2)

        let t1Split1 = client1.getTreatment("split1")
        let t1Split2 = client1.getTreatment("split2")

        client1.destroy()

        // Factory 2
        let reqManager2 = HttpRequestManagerTestDispatcher(dispatcher: buildBasicDispatcher(factoryNumber: 2),
                                                          streamingHandler: buildStreamingHandler())
        httpClient2 = DefaultHttpClient(session: session, requestManager: reqManager2)


        let builder2 = DefaultSplitFactoryBuilder()
        _ = builder2.setHttpClient(httpClient2)
        _ = builder2.setReachabilityChecker(ReachabilityMock())
        let factory2 = builder2.setApiKey(apiKey2).setKey(key)
            .setConfig(splitConfig).build()!

        let client2 = factory2.client

        let sdkReadyExpectation2 = XCTestExpectation(description: "SDK READY Expectation")

        client2.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation2.fulfill()
        }

        client2.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation2.fulfill()
        }

        wait(for: [sdkReadyExpectation2, sseExp[1]], timeout: 5)

        let t2Split1 = client2.getTreatment("split1")
        let t2Split2 = client2.getTreatment("split2")

        streamingBinding?.push(message: ":keepalive")

        testSplitsUpdate(changeNumber: changeNumberF2)

        client2.destroy()

        XCTAssertEqual("on", t1Split1)
        XCTAssertEqual("control", t1Split2)
        XCTAssertEqual(-1, firstChangeNumbers[1])
        XCTAssertEqual(changeNumberF1, lastChangeNumbers[1])

        XCTAssertEqual("control", t2Split1)
        XCTAssertEqual("on", t2Split2)
        XCTAssertEqual(-1, firstChangeNumbers[2])
        XCTAssertEqual(changeNumberF2, lastChangeNumbers[2])
    }

    private func testSplitsUpdate(changeNumber: Int64) {
        splitsChangesExp = XCTestExpectation()
        streamingBinding?.push(message: StreamingIntegrationHelper.splitUpdateMessage(timestamp: nextTimestamp(), changeNumber: Int(changeNumber)))
        wait(for: [splitsChangesExp!], timeout: 4)
        ThreadUtils.delay(seconds: 0.2)
    }

    private func buildBasicDispatcher(factoryNumber: Int) -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let respChangeNumber = Self.changeNumberBase + Int64(factoryNumber)
                self.lastChangeNumbers[factoryNumber] = request.parameters?["since"] as? Int64 ?? 0
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
            let exp = self.sseExp[self.sseExpIndex]
            self.sseExpIndex+=1
            exp.fulfill()
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



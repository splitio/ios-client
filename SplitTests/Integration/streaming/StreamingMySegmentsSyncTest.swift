//
//  StreamingMySegmentsSyncTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class StreamingMySegmentsSyncTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuth = false
    var isSseConnected = false
    var streamingBinding: TestStreamResponseBinding?
    let mySegExp = XCTestExpectation(description: "MySeg exp")
    let splitsChgExp = XCTestExpectation(description: "Splits chg exp")
    let kMaxSseAuthRetries = 3
    var sseAuthHits = 0
    var sseConnHits = 0
    var mySegmentsHits = 0
    var splitsChangesHits = 0
    // treaments "on" -> sdk ready, "on" -> full ssync streaming
    // , "free", "contra", "off" -> Push messages
    var treatments = ["on", "on", "free", "conta", "off"]
    var numbers = [500, 1000, 2000, 3000, 4000]
    var changes: String!
    var mySegments = [String]()
    var exps = [XCTestExpectation]()
    var sseExp = XCTestExpectation()
    let kInitialChangeNumber = 1000
    var expIndex = 0

    override func setUp() {
        expIndex = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
        loadMySegments()
    }

    func testInit() {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        splitConfig.isDebugModeEnabled = true

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let  expTimeout:  TimeInterval = 5

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        for i in 0..<5 {
            exps.insert(XCTestExpectation(description: "Exp changes \(i)"), at: i)
        }

        client.on(event: SplitEvent.sdkReady) {
            print("READY!!")
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp, curExp()], timeout: expTimeout)
        
        // Sending first push to enable streaming
        streamingBinding?.push(message: ":keepalive")
        wait(for: [curExp()], timeout: expTimeout)
        
        let splitName = "workm"
        let treatmentReady = client.getTreatment(splitName)
        print("treatmentReady")

        streamingBinding?.push(message:
            StreamingIntegrationHelper.mySegmentNoPayloadMessage(timestamp: numbers[0]))
        wait(for: [curExp()], timeout: expTimeout)

        justWait() // wait to my segments be updated
        let treatmentFirst = client.getTreatment(splitName)
        print("treatmentFirst")
        streamingBinding?.push(message:
            StreamingIntegrationHelper.mySegmentNoPayloadMessage(timestamp: numbers[1]))
        wait(for: [curExp()], timeout: expTimeout)

        justWait() // wait to my segments be updated
        let treatmentSec = client.getTreatment(splitName)
        print("treatmentSec")
        streamingBinding?.push(message:
            StreamingIntegrationHelper.mySegmentNoPayloadMessage(timestamp: numbers[2]))
        wait(for: [curExp()], timeout: expTimeout)

        justWait() // wait to my segments be updated
        let treatmentOld = client.getTreatment(splitName)

        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual("free", treatmentFirst)
        XCTAssertEqual("on", treatmentSec)
        XCTAssertEqual("on", treatmentOld)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let hitNumber = self.splitsChangesHits
                self.splitsChangesHits+=1
                var change: String!
                if hitNumber == 0 {
                    change = self.changes
                } else {
                    change = IntegrationHelper.emptySplitChanges(since: 100, till: 100)
                }
                return TestDispatcherResponse(code: 200, data: Data(change.utf8))

            case let(urlString) where urlString.contains("mySegments"):
                
                let hitNumber = self.mySegmentsHits
                self.mySegmentsHits+=1
                let exp = self.exps[hitNumber]
                let respData = self.mySegments[hitNumber]
                if hitNumber < self.exps.count {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        exp.fulfill()
                    }
                }
                return TestDispatcherResponse(code: 200, data: Data(respData.utf8))

            case let(urlString) where urlString.contains("auth"):
                self.sseAuthHits+=1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseConnHits+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                print("SSEE!!")
                self.sseExp.fulfill()
            }
            return self.streamingBinding!
        }
    }

    private func loadChanges() {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = 500
        change?.till = 500
        changes = (try? Json.encodeToJson(change)) ?? IntegrationHelper.emptySplitChanges
    }

    private func loadMySegments() {
        for _ in 1..<10 {
            mySegments.append(IntegrationHelper.emptyMySegments)
        }
        mySegments.insert(IntegrationHelper.mySegments(names: ["new_segment"]), at: 2)
    }

    private func justWait() {
        //ThreadUtils.delay(seconds: 2)
    }
    
    private func curExp() -> XCTestExpectation {
        var index = 0
        DispatchQueue.global().sync {
            index = self.expIndex
            self.expIndex+=1
        }
        return exps[index]
    }
}





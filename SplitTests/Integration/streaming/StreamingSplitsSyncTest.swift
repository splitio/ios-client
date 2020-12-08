//
//  StreamingSplitsSyncTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class StreamingSplitsSyncTest: XCTestCase {
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
    var changes = [String]()
    var sseExp: XCTestExpectation!
    var exps = [XCTestExpectation]()
    let kInitialChangeNumber = 1000
    var expIndex: Int = 0

    override func setUp() {
        expIndex = 0
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadChanges()
    }

    func testInit() {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999
        //splitConfig.isDebugModeEnabled = true
        
        sseExp = XCTestExpectation()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let expTimeout:  TimeInterval = 10

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        for i in 0..<5 {
            exps.append(XCTestExpectation(description: "Exp changes \(i)"))
        }

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp, curExp()], timeout: expTimeout)
        streamingBinding?.push(message: "id:a62260de-13bb-11eb-adc1-0242ac120002") // send msg to confirm streaming connection ok
        
        wait(for: [curExp()], timeout: expTimeout)

        let splitName = "workm"
        let treatmentReady = client.getTreatment(splitName)
        print("treatmentReady: \(treatmentReady)")
        streamingBinding?.push(message:
            StreamingIntegrationHelper.splitUpdateMessage(timestamp: numbers[2],
                                                          changeNumber: numbers[2]))
        wait(for: [curExp()], timeout: expTimeout)

        let treatmentFirst = client.getTreatment(splitName)
        print("treatmentFirst: \(treatmentFirst)")

        streamingBinding?.push(message:
            StreamingIntegrationHelper.splitUpdateMessage(timestamp: numbers[3],
                                                          changeNumber: numbers[3]))
        wait(for: [curExp()], timeout: expTimeout)
        let treatmentSec = client.getTreatment(splitName)
        print("treatmentSec: \(treatmentSec)")

        streamingBinding?.push(message:
            StreamingIntegrationHelper.splitUpdateMessage(timestamp: 100,
                                                          changeNumber: 100))
        waitForUpdate()
        let treatmentOld = client.getTreatment(splitName)
        print("treatmentOld: \(treatmentOld)")

        XCTAssertEqual("on", treatmentReady)
        XCTAssertEqual("free", treatmentFirst)
        XCTAssertEqual("conta", treatmentSec)
        XCTAssertEqual("conta", treatmentOld)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                let hitNumber = self.getAndUpdateHit()
                if hitNumber < self.exps.count {
                    let exp = self.exps[hitNumber]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        exp.fulfill()
                    }
                    return TestDispatcherResponse(code: 200, data: Data(self.changes[hitNumber].utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                self.mySegmentsHits+=1
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
            self.sseConnHits+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.sseExp.fulfill()
            }
            return self.streamingBinding!
        }
    }

    private func getChanges(withTreatment: String, since: Int, till: Int) -> String {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(since)
        change?.till = Int64(till)
        let split = change?.splits?[0]
        if let partitions = split?.conditions?[1].partitions {
            let partition = partitions.filter { $0.treatment == withTreatment }
            partition[0].size = 100

            for partition in partitions where partition.treatment != withTreatment {
                partition.size = 0
            }
        }
        return (try? Json.encodeToJson(change)) ?? ""
    }

    private func loadChanges() {
        for i in 0..<5 {
            let change = getChanges(withTreatment: self.treatments[i],
                                    since: self.numbers[i],
                                    till: self.numbers[i])
            changes.insert(change, at: i)
        }
    }

    private func waitForUpdate() {
        ThreadUtils.delay(seconds: 2)
    }
    
    private func curExp() -> XCTestExpectation {
        var index = 0
        DispatchQueue.global().sync {
            index = self.expIndex
            self.expIndex+=1
        }
        return exps[index]
    }
    
    private func getAndUpdateHit() -> Int {
        var hitNumber = 0
        DispatchQueue.global().sync {
            hitNumber = self.splitsChangesHits
            self.splitsChangesHits+=1
        }
        return hitNumber
    }
}





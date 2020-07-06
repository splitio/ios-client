//
//  SplitChangesTest.swift
//  SplitChangesTest
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitChangesTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    let kChangeNbInterval: Int64 = 86400
    var reqChangesIndex = 0
    var serverUrl = ""
    let kMatchingKey = "CUSTOMER_ID"

    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    
    override func setUp() {
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {

        webServer = MockWebServer()
        let respData = responseSlitChanges()
        var responses = [MockedResponse]()
        for data in respData {
            responses.append(MockedResponse(code: 200, data: try? Json.encodeToJson(data)))
        }

        webServer.routeGet(path: "/mySegments/:user_id",
                           data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, "
                            + "{ \"id\":\"id1\", \"name\":\"segment2\"}]}")

        webServer.route(method: .get, path: "/splitChanges") { request in
            let index = self.getAndIncrement()
            if index < self.spExp.count {
                if index > 0 {
                    self.spExp[index - 1].fulfill()
                }
                return responses[index]
            } else if index == self.spExp.count {
                self.spExp[index - 1].fulfill()
            }
            return MockedResponse(code: 200, data: "{\"splits\":[], \"since\": 9567456937865, \"till\": 9567456937869 }")
        }

        webServer.route(method: .post, path: "/testImpressions/bulk") { request in
            self.impHit = try? TestUtils.impressionsFromHit(request: request)
            self.impExp.fulfill()
            return MockedResponse(code: 200, data: nil)
        }
        webServer.start()
        serverUrl = webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }

    // MARK: Test
    /// Getting changes from server and test treatments and change number
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_b"
        let trafficType = "client"
        var impressions = [String:Impression]()
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.segmentsRefreshRate = 45
        splitConfig.featuresRefreshRate = 5
        splitConfig.impressionRefreshRate = splitConfig.featuresRefreshRate * 6
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        splitConfig.impressionListener = { impression in
            impressions[IntegrationHelper.buildImpressionKey(impression: impression)] = impression
        }
        
        let key: Key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [sdkReady], timeout: 30)

        for i in 0..<4 {
            wait(for: [spExp[i]], timeout: 30)
            treatments.append(client.getTreatment("test_feature"))
        }

        wait(for: [impExp], timeout: 40)

        var impLis = [Impression]()
        impLis.append(impressions[IntegrationHelper.buildImpressionKey(key: kMatchingKey,
                                                                       splitName: "test_feature", treatment: "on_0")] ?? Impression())
        impLis.append(impressions[IntegrationHelper.buildImpressionKey(key: kMatchingKey,
                                                                       splitName: "test_feature", treatment: "off_1")] ?? Impression())
        impLis.append(impressions[IntegrationHelper.buildImpressionKey(key: kMatchingKey,
                                                                       splitName: "test_feature", treatment: "on_2")] ?? Impression())

        XCTAssertTrue(sdkReadyFired)
        for i in 0..<4 {
            let even = ((i + 2) % 2 == 0)
            XCTAssertEqual((even ? "on_\(i)" : "off_\(i)"), treatments[i])
        }
        XCTAssertNotNil(impLis[0])

        XCTAssertNotNil(impLis[1])
        XCTAssertNotNil(impLis[2])
        XCTAssertEqual(1567456937865, impLis[0].changeNumber)
        XCTAssertEqual(1567456937865 + kChangeNbInterval, impLis[1].changeNumber)
        XCTAssertEqual(1567456937865 + kChangeNbInterval * 2, impLis[2].changeNumber)
        XCTAssertEqual(1, impHit?.count)
        XCTAssertEqual(4, impHit?[0].keyImpressions.count)
        let imp0 = impHit?[0].keyImpressions[0]
        let imp3 = impHit?[0].keyImpressions[3]
        XCTAssertEqual("on_0", imp0?.treatment)
        XCTAssertEqual(1567456937865, imp0?.changeNumber)

        XCTAssertEqual("off_3", imp3?.treatment)
        XCTAssertEqual(1567456937865  + kChangeNbInterval * 3, imp3?.changeNumber)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    private func  responseSlitChanges() -> [SplitChange] {
        var changes = [SplitChange]()


        var prevChangeNumber: Int64 = 0
        for i in 0..<4 {
            let c = loadSplitsChangeFile()!
            if prevChangeNumber != 0 {
                c.since = prevChangeNumber
                c.till = prevChangeNumber + kChangeNbInterval
            }
            prevChangeNumber = c.till!
            let split = c.splits![0]
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

    private func impressionsHits() -> [ClientRequest] {
        return webServer.receivedRequests.filter { $0.path == "/testImpressions/bulk"}
    }

    private func getAndIncrement() -> Int {
        var i = 0;
        DispatchQueue.global().sync {
            i = self.reqChangesIndex
            self.reqChangesIndex+=1
        }
        return i
    }
}


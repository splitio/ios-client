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

    var exp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]
    
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
        webServer.routeGet(path: "/mySegments/:user_id", data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}")
        webServer.route(method: .get, path: "/splitChanges?since=:param", responses: responses) { index in
            if index > 0 {
                self.exp[index - 1].fulfill()
                print("exp: \(index) -> \(index - 1)")
            }
        }
        webServer.start()
    }
    
    private func stopServer() {
        webServer.stop()
    }
    
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
         var impressions = [String:Impression]()
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 5
        splitConfig.impressionRefreshRate = 5
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.targetSdkEndPoint = "http://localhost:8080"
        splitConfig.targetEventsEndPoint = "http://localhost:8080"
        splitConfig.impressionListener = { impression in
            impressions[self.buildImpressionKey(impression: impression)] = impression
        }
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        client.on(event: SplitEvent.sdkReadyTimedOut) {
            //self.exp[0].fulfill()
        }
        
        wait(for: [sdkReady], timeout: 100000)

        for i in 0..<4 {
            wait(for: [exp[i]], timeout: 100000)
            print("wait: \(i)")
            treatments.append(client.getTreatment("test_feature"))
            print("tr: \(treatments[i])")
            if i < exp.count {

            }
        }
        
        let i1 = impressions[buildImpressionKey(key: "CUSTOMER_ID", splitName: "test_feature", treatment: "on_0")]
        let i2 = impressions[buildImpressionKey(key: "CUSTOMER_ID", splitName: "test_feature", treatment: "off_1")]
        let i3 = impressions[buildImpressionKey(key: "CUSTOMER_ID", splitName: "test_feature", treatment: "on_2")]

        XCTAssertTrue(sdkReadyFired)
        for i in 0..<4 {
            let even = ((i + 2) % 2 == 0)
            XCTAssertEqual((even ? "on_\(i)" : "off_\(i)"), treatments[i])
        }
        XCTAssertNotNil(i1)

        XCTAssertNotNil(i2)
        XCTAssertNotNil(i3)
        XCTAssertEqual(1567456937865, i1?.changeNumber)
        XCTAssertEqual(1567456937865 + kChangeNbInterval, i2?.changeNumber)
        XCTAssertEqual(1567456937865 + kChangeNbInterval * 2, i3?.changeNumber)
        //XCTAssertEqual("not in split", i1?.label)

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

    private func buildImpressionKey(impression: Impression) -> String {
        return buildImpressionKey(key: impression.keyName!, splitName: impression.feature!, treatment: impression.treatment!)
    }
    
    private func buildImpressionKey(key: String, splitName: String, treatment: String) -> String {
        return "(\(key)_\(splitName)_\(treatment)"
    }
}


//
//  SplitChangeFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 3/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class SplitChangeFetcherTests: XCTestCase {

    var splitChangeFetcher: SplitChangeFetcher!
    var splitCache: SplitCache!

    override func setUp() {
        splitCache = SplitCache(fileStorage: FileStorageStub())
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache)
    }

    override func tearDown() {
    }

    func testFetchCount() {
        
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_1"))
        
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache)
        let response = try? splitChangeFetcher.fetch(since: -1)
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertTrue(response!.splits!.count > 0, "Split count should be greater than 0")
        }
    }

    func testChangeFetch() {
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_2"))
        
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache)
        let response = try? splitChangeFetcher.fetch(since: -1)
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response!.splits!.count, 1, "Splits count should be 1")
            let split = response!.splits![0];
            XCTAssertEqual(split.name, "FACUNDO_TEST", "Split name value")
            XCTAssertFalse(split.killed!, "Split killed value should be false")
            XCTAssertEqual(split.status, .active, "Split status should be 'Active'")
            XCTAssertEqual(split.trafficTypeName, "account", "Split traffict type should be account")
            XCTAssertEqual(split.defaultTreatment, "off", "Default treatment value")
            XCTAssertNotNil(split.conditions, "Conditions should not be nil")
            XCTAssertNotNil(split.configurations, "Configurations should not be nil")
            XCTAssertNotNil(split.configurations?["on"])
            XCTAssertNotNil(split.configurations?["off"])
            XCTAssertEqual(response!.since, -1, "Since should be -1")
            XCTAssertEqual(response!.till, 1506703262916, "Check till value")
            XCTAssertNil(split.algo, "Algo should be nil")
        }
    }

    func testSplitsTillAndSince() {
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_3"))
        
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache)
        var response: SplitChange?
        var errorHasOccurred = false
        do {
            response = try splitChangeFetcher.fetch(since: -1)
        } catch {
            errorHasOccurred = true
        }
        XCTAssertTrue(errorHasOccurred, "An exception should be raised")
        XCTAssertTrue(response == nil, "Response should be nil")
    }
    
    func getChanges(fileName: String) -> SplitChange? {
        var change: SplitChange?
        if let content = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json") {
            change = try? Json.encodeFrom(json: content, to: SplitChange.self)
        }
        return change
    }
}

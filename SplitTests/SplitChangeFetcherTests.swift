//
//  SplitChangeFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 3/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs

@testable import Split

class SplitChangeFetcherTests: XCTestCase {
    
    var splitChangeFetcher: SplitChangeFetcher!
    var cache: SplitCache!
    
    override func setUp() {
        cache = SplitCache(storage: MemoryStorage())
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: RestClient(), splitCache: cache)
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }
    
    func testFetchCount() {
        stub(condition: isPath("/api/splitChanges")) { _ in
            let stubPath = OHPathForFile("splitchanges_1.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        sleep(1) // Time to load the file
        let response = try? splitChangeFetcher.fetch(since: -1)
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertTrue(response!.splits!.count > 0, "Split count should be greater than 0")
        }
    }
    
    func testChangeFetch() {
        stub(condition: pathMatches("/api/splitChanges")) { _ in
            let stubPath = OHPathForFile("splitchanges_2.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        sleep(1) // Time to load the file
        let response = try? splitChangeFetcher.fetch(since: -1)
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response!.splits!.count, 1, "Splits count should be 1")
            let split = response!.splits![0];
            XCTAssertEqual(split.name, "FACUNDO_TEST", "Split name value")
            XCTAssertFalse(split.killed!, "Split killed value should be false")
            XCTAssertEqual(split.status, Status.Active, "Split status should be 'Active'")
            XCTAssertEqual(split.trafficTypeName, "account", "Split traffict type should be account")
            XCTAssertEqual(split.defaultTreatment, "off", "Default treatment value")
            XCTAssertNotNil(split.conditions, "Conditions should not be nil")
            XCTAssertEqual(response!.since, -1, "Since should be -1")
            XCTAssertEqual(response!.till, 1506703262916, "Check till value")
            XCTAssertNil(split.algo, "Algo should be nil")
        }
    }
    
    func testSplitsTillAndSince() {
        stub(condition: isPath("/api/splitChanges")) { _ in
            let stubPath = OHPathForFile("splitchanges_3.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        sleep(2) // Time to load the file
        let response = try? splitChangeFetcher.fetch(since: -1)
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertNil(response!.splits, "Splits should be nil")
            XCTAssertNil(response!.since, "Since should be nil")
            XCTAssertNil(response!.till, "Till should be nil")
        }
    }
}

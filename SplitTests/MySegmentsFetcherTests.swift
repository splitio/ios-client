//
//  MySegmentsFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 4/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs

@testable import Split

class MySegmentsFetcherTests: XCTestCase {
    
    var mySegmentsFetcher: MySegmentsChangeFetcher!
    
    override func setUp() {
        let storage = FileAndMemoryStorage()
        mySegmentsFetcher = HttpMySegmentsFetcher(restClient: RestClient(), storage: storage)
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }
    
    func testOneSegmentFetch() {
        stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
            let stubPath = OHPathForFile("mysegments_1.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        sleep(1) // Time to load the file
        let response = try? mySegmentsFetcher.fetch(user: "test")
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertTrue(response!.count > 0, "Response count should be greater than 0")
            XCTAssertEqual(response![0], "splitters", "First segment should be named 'splitters'")
        }
    }
    
    func testThreeSegmentsFetch() {
        stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
            let stubPath = OHPathForFile("mysegments_2.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }

        sleep(1) // Time to load the file
        let response = try? mySegmentsFetcher.fetch(user: "test")
        
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response!.count, 2, "Response count should be 2")
            XCTAssertEqual(response![0], "test", "First segment should be named 'test'")
            XCTAssertEqual(response![1], "test1", "Second segment should be named 'test1'")
        }
    }
    
    func testEmptySegmentFetch() {
        stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
            let stubPath = OHPathForFile("mysegments_3.json", type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        sleep(1) // Time to load the file
        let response = try? mySegmentsFetcher.fetch(user: "test")
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response!.count, 0, "Response count should empty")
        }
    }
}

//
//  MySegmentsFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 4/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class MySegmentsFetcherTests: XCTestCase {

    var mySegmentsFetcher: MySegmentsChangeFetcher!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcher(restClient: RestClient(), mySegmentsCache: InMemoryMySegmentsCache(segments: Set<String>()))
    }

    override func tearDown() {
    }

    func testOneSegmentFetch() {
        let restClient: RestClientMySegments = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(segments: ["splitters"])
        mySegmentsFetcher = HttpMySegmentsFetcher(restClient: restClient, mySegmentsCache: InMemoryMySegmentsCache(segments: Set<String>()))
        var response: [String]? = nil
        do {
            response = try mySegmentsFetcher.fetch(user: "test")
        } catch {
        }

        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertTrue(response.count > 0, "Response count should be greater than 0")
            XCTAssertEqual(response[0], "splitters", "First segment should be named 'splitters'")
        }
    }

    func testThreeSegmentsFetch() {
        let restClient: RestClientMySegments = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(segments: ["test", "test1"])
        mySegmentsFetcher = HttpMySegmentsFetcher(restClient: restClient, mySegmentsCache: InMemoryMySegmentsCache(segments: Set<String>()))
        var response: [String]? = nil
        do {
            response = try mySegmentsFetcher.fetch(user: "test")
        } catch {
        }

        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response.count, 2, "Response count should be 2")
            XCTAssertEqual(response[0], "test", "First segment should be named 'test'")
            XCTAssertEqual(response[1], "test1", "Second segment should be named 'test1'")
        }
    }

    func testEmptySegmentFetch() {
        let restClient: RestClientMySegments = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(segments: [])
        mySegmentsFetcher = HttpMySegmentsFetcher(restClient: restClient, mySegmentsCache: InMemoryMySegmentsCache(segments: Set<String>()))
        var response: [String]? = nil
        do {
            response = try mySegmentsFetcher.fetch(user: "test")
        } catch {
        }
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response.count, 0, "Response count should empty")
        }
    }
}

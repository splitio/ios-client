//
//  HttpMySegmentsFetcherTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpMySegmentsFetcherTests: XCTestCase {
    
    var restClient: RestClientStub!
    var fetcher: HttpMySegmentsFetcher!
    var metricsManager: MetricsManagerStub!
    
    override func setUp() {
        restClient = RestClientStub()
        metricsManager = MetricsManagerStub()
        fetcher = DefaultHttpMySegmentsFetcher(restClient: restClient, metricsManager: metricsManager)
    }
    
    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(userKey: "user")
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertFalse(metricsManager.countCalled)
        XCTAssertFalse(metricsManager.timeCalled)
    }
    
    func testSuccessFulFetch() throws {
        restClient.isServerAvailable = true
        restClient.update(segments: ["s1", "s2", "s3"])
        
        let c = try fetcher.execute(userKey: "user")
        
        XCTAssertEqual(3, c?.count)
        XCTAssertTrue(metricsManager.countCalled)
        XCTAssertTrue(metricsManager.timeCalled)
    }
    
    override func tearDown() {
    }
}


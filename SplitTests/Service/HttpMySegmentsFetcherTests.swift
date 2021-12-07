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
    var telemetryProducer: TelemetryStorageStub!
    
    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        fetcher = DefaultHttpMySegmentsFetcher(restClient: restClient, telemetryProducer: telemetryProducer)
    }
    
    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(userKey: "user", headers: nil)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
    }
    
    func testSuccessFulFetch() throws {
        restClient.isServerAvailable = true
        restClient.update(segments: ["s1", "s2", "s3"])
        
        let c = try fetcher.execute(userKey: "user", headers: nil)
        
        XCTAssertEqual(3, c?.count)
    }
    
    override func tearDown() {
    }
}


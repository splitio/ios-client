//
//  HttpSplitFetcherTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpSplitFetcherTests: XCTestCase {
    
    var restClient: RestClientStub!
    var fetcher: HttpSplitFetcher!
    var telemetryProducer: TelemetryStorageStub!
    
    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        fetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                          syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }
    
    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(since: 1, till: nil, headers: nil)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
    }
    
    func testSuccessFullFetch() throws {
        restClient.isServerAvailable = true
        restClient.update(changes: [newChange(since: 1, till: 2), newChange(since: 2, till: 2)])
        
        let c = try fetcher.execute(since: 1, till: nil, headers: nil)
        
        XCTAssertEqual(1, c.since)
        XCTAssertEqual(2, c.till)
        XCTAssertEqual(0, c.splits.count)
    }
    
    func newChange(since: Int64, till: Int64, splits: [Split] = []) -> SplitChange {
        return SplitChange(splits: [], since: since, till: till)
    }

    override func tearDown() {
    }
}


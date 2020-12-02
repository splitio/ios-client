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
    
    override func setUp() {
        restClient = RestClientStub()
        fetcher = DefaultHttpSplitFetcher(restClient: restClient)
    }
    
    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(since: 1)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
    }
    
    func testSuccessFulFetch() throws {
        restClient.isServerAvailable = true
        restClient.update(changes: [newChange(since: 1, till: 2), newChange(since: 2, till: 2)])
        
        let c = try fetcher.execute(since: 1)
        
        XCTAssertEqual(2, c?.since)
        XCTAssertEqual(2, c?.till)
        XCTAssertEqual(0, c?.splits?.count)
    }
    
    func newChange(since: Int64, till: Int64, splits: [Split] = []) -> SplitChange {
        let change = SplitChange()
        change.splits = []
        change.since = since
        change.till = till
        return change
    }
    override func tearDown() {
    }
}


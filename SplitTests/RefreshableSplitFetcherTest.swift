//
//  RefreshableSplitFetcherTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/05/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class RefreshableSplitFetcherTest: XCTestCase {

    private var splitCache: SplitCacheStub!
    private var splitChangeFetcher: SplitChangeFetcherStub!

    override func setUp() {
        splitCache = SplitCacheStub(splits: generateSplits(), changeNumber: 1000)
        splitChangeFetcher = SplitChangeFetcherStub()
    }


    func testClearExpiredCache() {
        let expiration: Int = 60 * 60 * 24 * 5 // Five days
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: expiration,
                dispatchGroup: nil,
                eventsManager: SplitEventsManagerStub())
        let expectation = XCTestExpectation(description: "Clear")
        splitCache.clearExpectation = expectation
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration - 10000 // expired
        fetcher.start()

        wait(for: [expectation], timeout: 40)
        XCTAssertEqual(splitCache.clearCallCount, 1)
        XCTAssertEqual(splitCache.getChangeNumber(), Int64(-1))
    }

    func testClearNonExpiredCache() {
        let expiration: Int = 60 * 60 * 24 * 5 // Five days
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: expiration,
                dispatchGroup: nil,
                eventsManager: SplitEventsManagerStub())
        let expectation = XCTestExpectation(description: "Clear")
        splitChangeFetcher.fetchExpectation = expectation
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration + 60 * 60 * 24 // no expired
        fetcher.start()

        wait(for: [expectation], timeout: 40)
        XCTAssertEqual(splitCache.clearCallCount, 0)
        XCTAssertEqual(splitCache.getChangeNumber(), 1000)
    }

    func testClearMinusOneChangeNumberCache() {
        let expiration = 60 * 60 * 24 * 10
        splitCache = SplitCacheStub(splits: generateSplits(), changeNumber: -1)
        splitCache.timestamp = Int(Date().timeIntervalSince1970) -  expiration - 10000 // expired 1000 seconds ago
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: expiration,
                dispatchGroup: nil,
                eventsManager: SplitEventsManagerStub())
        let expectation = XCTestExpectation(description: "Clear")
        splitChangeFetcher.fetchExpectation = expectation

        fetcher.start()

        wait(for: [expectation], timeout: 40)
        XCTAssertEqual(splitCache.clearCallCount, 0)
        XCTAssertEqual(splitCache.getChangeNumber(), -1)
    }

    private func generateSplits() -> [Split] {
        var splits = [Split]()
        for i in 1..<10 {
            let s = Split()
            s.name = "s\(i)"
            splits.append(s)
        }
        return splits
    }
}

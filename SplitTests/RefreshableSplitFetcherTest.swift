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
    private var changeNumber: Int64!

    override func setUp() {
        changeNumber = Int64((Date().timeIntervalSince1970 - 60 * 24 * 5) * 1000)
        splitCache = SplitCacheStub(splits: generateSplits(), changeNumber: changeNumber)
        splitChangeFetcher = SplitChangeFetcherStub()
    }


    func testClearExpiredCache() {
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: 60 * 23,
                dispatchGroup: nil,
                eventsManager: SplitEventsManagerStub())
        let expectation = XCTestExpectation(description: "Clear")
        splitCache.clearExpectation = expectation

        fetcher.start()

        wait(for: [expectation], timeout: 40)
        XCTAssertEqual(splitCache.clearCallCount, 1)
        XCTAssertEqual(splitCache.getChangeNumber(), Int64(-1))
    }

    func testClearNonExpiredCache() {
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: 60 * 24 * 10,
                dispatchGroup: nil,
                eventsManager: SplitEventsManagerStub())
        let expectation = XCTestExpectation(description: "Clear")
        splitChangeFetcher.fetchExpectation = expectation

        fetcher.start()

        wait(for: [expectation], timeout: 40)
        XCTAssertEqual(splitCache.clearCallCount, 0)
        XCTAssertEqual(splitCache.getChangeNumber(), changeNumber)
    }

    func testClearMinusOneChangeNumberCache() {
        splitCache = SplitCacheStub(splits: generateSplits(), changeNumber: -1)
        let fetcher = DefaultRefreshableSplitFetcher(splitChangeFetcher: splitChangeFetcher,
                splitCache: splitCache,
                interval: 1,
                cacheExpiration: 60 * 24 * 10,
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

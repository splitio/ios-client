//
//  SplitFilterCacheUpdaterTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitFilterCacheUpdaterTest: XCTestCase {

    override func setUp() {
    }

    func testChangeQueryStringAndKeepNames() {
        // Stored query string is different than current one.
        // Testing that some splits has to be removed
        // and some maintained

        var splits = [Split]()
        for i in 0..<5 {
            let split = Split()
            split.name = "sp\(i)"
            splits.append(split)
        }

        let splitCache = SplitCacheStub(splits: splits, changeNumber: 100, queryString: "q=2")

        let filters = [SplitFilter.byName(["sp1", "sp2", "sp3"])]
        SplitFilterCacheUpdater.update(filters: filters, currentQueryString: "q=1", splitCache: splitCache)

        let cachedSplits = splitCache.getSplits()

        XCTAssertNotNil(cachedSplits["sp1"])
        XCTAssertNotNil(cachedSplits["sp2"])
        XCTAssertNotNil(cachedSplits["sp3"])
        XCTAssertNil(cachedSplits["sp0"])
        XCTAssertNil(cachedSplits["sp4"])
    }

    func testChangeQueryStringAndKeepPrefixes() {
        // Stored query string is different than current one.
        // Testing that some splits has to be removed
        // and some maintained

        var splits = [Split]()
        for i in 0..<5 {
            let split = Split()
            split.name = "sp\(i)__split"
            splits.append(split)
        }

        let splitCache = SplitCacheStub(splits: splits, changeNumber: 100, queryString: "q=2")

        let filters = [SplitFilter.byPrefix(["sp1", "sp2", "sp3"])]
        SplitFilterCacheUpdater.update(filters: filters, currentQueryString: "q=1", splitCache: splitCache)

        let cachedSplits = splitCache.getSplits()

        XCTAssertNotNil(cachedSplits["sp1__split"])
        XCTAssertNotNil(cachedSplits["sp2__split"])
        XCTAssertNotNil(cachedSplits["sp3__split"])
        XCTAssertNil(cachedSplits["sp0__split"])
        XCTAssertNil(cachedSplits["sp4__split"])
    }

    func testChangeQueryStringAndKeepBoth() {
        // Stored query string is different than current one.
        // Testing that some splits has to be removed
        // and some maintained

        var splits = [Split]()
        for i in 0..<5 {
            var split = Split()
            split.name = "sp\(i)"
            splits.append(split)

            split = Split()
            split.name = "sp\(i)__split"
            splits.append(split)
        }

        let splitCache = SplitCacheStub(splits: splits, changeNumber: 100, queryString: "q=2")

        let filters = [SplitFilter.byName(["sp1", "sp2", "sp3"]), SplitFilter.byPrefix(["sp1", "sp2", "sp3"])]
        SplitFilterCacheUpdater.update(filters: filters, currentQueryString: "q=1", splitCache: splitCache)

        let cachedSplits = splitCache.getSplits()

        XCTAssertNotNil(cachedSplits["sp1"])
        XCTAssertNotNil(cachedSplits["sp2"])
        XCTAssertNotNil(cachedSplits["sp3"])
        XCTAssertNil(cachedSplits["sp0"])
        XCTAssertNil(cachedSplits["sp4"])

        XCTAssertNotNil(cachedSplits["sp1__split"])
        XCTAssertNotNil(cachedSplits["sp2__split"])
        XCTAssertNotNil(cachedSplits["sp3__split"])
        XCTAssertNil(cachedSplits["sp0__split"])
        XCTAssertNil(cachedSplits["sp4__split"])
    }

    func testNoChangedQueryString() {
        // Stored query string is equal than current one.
        // Testing that some splits has to be removed
        // and some maintained

        var splits = [Split]()
        for i in 0..<5 {
            let split = Split()
            split.name = "sp\(i)"
            splits.append(split)
        }

        let splitCache = SplitCacheStub(splits: splits, changeNumber: 100, queryString: "q=1")

        let filters = [SplitFilter.byName(["sp1", "sp2", "sp3"])]
        SplitFilterCacheUpdater.update(filters: filters, currentQueryString: "q=1", splitCache: splitCache)

        let cachedSplits = splitCache.getSplits()

        XCTAssertNotNil(cachedSplits["sp1"])
        XCTAssertNotNil(cachedSplits["sp2"])
        XCTAssertNotNil(cachedSplits["sp3"])
        XCTAssertNotNil(cachedSplits["sp0"])
        XCTAssertNotNil(cachedSplits["sp4"])
    }

    func testChangedQueryStringNoSplitsToDelete() {
        // Should maintain all splits

        var splits = [Split]()
        for i in 0..<5 {
            let split = Split()
            split.name = "sp\(i)"
            splits.append(split)
        }

        let splitCache = SplitCacheStub(splits: splits, changeNumber: 100, queryString: "q=2")

        let filters = [SplitFilter.byName(["sp0", "sp4", "sp1", "sp2", "sp3"])]
        SplitFilterCacheUpdater.update(filters: filters, currentQueryString: "q=1", splitCache: splitCache)

        let cachedSplits = splitCache.getSplits()

        XCTAssertNotNil(cachedSplits["sp0"])
        XCTAssertNotNil(cachedSplits["sp1"])
        XCTAssertNotNil(cachedSplits["sp2"])
        XCTAssertNotNil(cachedSplits["sp3"])
        XCTAssertNotNil(cachedSplits["sp4"])
        XCTAssertEqual(5, cachedSplits.count)

    }

    override func tearDown() {
    }
}

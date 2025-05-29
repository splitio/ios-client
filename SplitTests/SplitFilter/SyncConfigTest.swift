//
//  SyncConfigTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SyncConfigTest: XCTestCase {
    override func setUp() {}

    func testFilterName() {
        // Testing basic by name filter creation
        // and checking correctnes in values
        let filter = SplitFilter.byName(["f0", "f1", "f2"])

        XCTAssertEqual(SplitFilter.FilterType.byName, filter.type)
        for (index, value) in filter.values.enumerated() {
            XCTAssertEqual("f\(index)", value)
        }
    }

    func testFilterByPrefix() {
        // Testing basic by prefix filter creation
        // and checking correctnes in values
        let filter = SplitFilter.byPrefix(["f0", "f1", "f2"])

        XCTAssertEqual(SplitFilter.FilterType.byPrefix, filter.type)
        for (index, value) in filter.values.enumerated() {
            XCTAssertEqual("f\(index)", value)
        }
    }

    func testSyncBuilder() {
        // Testing basic by prefix filter creation
        // and checking correctnes in values

        var byNameCount = 0
        var byPrefixCount = 0

        let config = SyncConfig.builder()
            .addSplitFilter(SplitFilter.byName(["f0", "f1", "f2"]))
            .addSplitFilter(SplitFilter.byName(["f0", "f1", "f2"]))
            .addSplitFilter(SplitFilter.byPrefix(["f0", "f1", "f2"]))
            .addSplitFilter(SplitFilter.byPrefix(["f0", "f1", "f2"]))
            .build()

        config.filters.forEach {
            if $0.type == .byName {
                byNameCount += 1
            } else {
                byPrefixCount += 1
            }
        }
        XCTAssertEqual(2, byNameCount)
        XCTAssertEqual(2, byPrefixCount)
    }

    func testInvalidFilterValuesDiscarded() {
        //        // Filters that doesn't pass split rules
        //        // has to be removed from the list
        //        // This test adds some invalid ones an thes correct deletion

        let byName = SplitFilter.byName(["", "f2"])
        let byPrefix = SplitFilter.byPrefix(["", "f2"])

        let config = SyncConfig.builder().addSplitFilter(byName).addSplitFilter(byPrefix).build()

        let byNameAdded = config.filters.filter { $0.type == .byName }
        let byPrefixAdded = config.filters.filter { $0.type == .byPrefix }

        XCTAssertEqual(1, byNameAdded.count)
        XCTAssertEqual(1, byPrefixAdded.count)
    }

    func testEmptyFilterValuesDiscarded() {
//     Empty lists should be discarded
        // Here we create two filters:
        // By name having no values and by prefix having all invalid values
        // No tests has to be added to SyncConfig

        let byName = SplitFilter.byName([])
        let byPrefix = SplitFilter.byPrefix([])

        let config = SyncConfig.builder().addSplitFilter(byName).addSplitFilter(byPrefix).build()

        XCTAssertEqual(0, config.filters.count)
    }

    override func tearDown() {}
}

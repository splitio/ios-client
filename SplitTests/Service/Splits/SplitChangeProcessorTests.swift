//
//  SplitChangeProcessorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

@testable import Split
import XCTest

class SplitChangeProcessorTests: XCTestCase {
    override func setUp() {}

    func testProcessNoSets() {
        let processor = DefaultSplitChangeProcessor(filterBySet: nil)

        let result = processor.process(createChange())

        XCTAssertEqual(11, result.activeSplits.count)
        XCTAssertEqual(2, result.archivedSplits.count)
    }

    func testProcessWithSets() {
        let filter = SplitFilter(type: .bySet, values: ["set1"])
        let processor = DefaultSplitChangeProcessor(filterBySet: filter)

        let result = processor.process(createChange())

        XCTAssertEqual(2, result.activeSplits.count)
        XCTAssertEqual(11, result.archivedSplits.count)
    }

    private func createChange() -> SplitChange {
        var splits = [Split]()
        for i in 0 ..< 7 {
            splits.append(TestingHelper.createSplit(name: "act_\(i)", status: .active))
        }

        for i in 0 ..< 2 {
            splits.append(TestingHelper.createSplit(name: "set_\(i)", status: .active, sets: ["set1", "set2"]))
        }

        splits.append(TestingHelper.createSplit(name: "set_3", status: .active, sets: ["set3"]))

        splits.append(TestingHelper.createSplit(name: "set_empty", status: .active, sets: []))

        for i in 0 ..< 2 {
            splits.append(TestingHelper.createSplit(name: "arc_\(i)", status: .archived))
        }
        return SplitChange(splits: splits, since: 1000, till: 2000)
    }
}

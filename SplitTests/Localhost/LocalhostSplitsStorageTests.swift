//
//  LocalhostSplitsStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 09/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostSplitStorageTests: XCTestCase {
    var splitStorage: SplitsStorage!

    override func setUp() {
        let splits = SplitTestHelper.createSplits(namePrefix: "test_split", count: 10)
        // Initialize splitStorage with a mock or actual implementation of SplitsStorage.
        splitStorage = LocalhostSplitsStorage()
        _ = splitStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: splits,
            archivedSplits: [],
            changeNumber: 1,
            updateTimestamp: 1))
    }

    override func tearDown() {
        splitStorage.destroy()
    }

    func testGetSplit() {
        let splitName = "test_split1"
        let split = splitStorage.get(name: splitName)
        // Check if the retrieved split matches the expected criteria.
        // This depends on your test setup and how splits are stored.
        XCTAssertEqual(split?.name, splitName, "Retrieved split does not match the requested name.")
    }

    func testGetManySplits() {
        let splitNames = ["test_split1", "test_split2"]
        let splits = splitStorage.getMany(splits: splitNames)
        XCTAssertEqual(splits.count, splitNames.count, "Number of retrieved splits does not match.")
        for name in splitNames {
            XCTAssertNotNil(splits[name], "Split \(name) was not found.")
        }
    }

    func testGetAllSplits() {
        let allSplits = splitStorage.getAll()
        // Perform checks based on your expected data.
        // For example, check if the count matches expected splits count.
        XCTAssertGreaterThan(allSplits.count, 0, "Get all should return more than 0 splits.")
    }

    func testUpdateSplitChange() {
        let splits = SplitTestHelper.createSplits(namePrefix: "new_split", count: 5)
        let splitChange = ProcessedSplitChange(
            activeSplits: splits,
            archivedSplits: [],
            changeNumber: 1,
            updateTimestamp: 1) // Provide necessary data
        let result = splitStorage.update(splitChange: splitChange)

        let loaded = splitStorage.getMany(splits: ["new_split1", "new_split2", "test_split1"])
        let loadedAll = splitStorage.getAll()

        XCTAssertTrue(result, "Update with splitChange should succeed.")
        XCTAssertEqual(2, loaded.count)
        XCTAssertEqual(5, loadedAll.count)
    }

    func testClear() {
        splitStorage.clear()
        let all = splitStorage.getAll()
        XCTAssertEqual(0, all.count)
    }

    func testDestroy() {
        splitStorage.destroy()
        let all = splitStorage.getAll()
        XCTAssertEqual(0, all.count)
    }

    func testGetCount() {
        let count = splitStorage.getCount()
        // Verify the count based on your expected data.
        // For example, if you know the exact number of splits that should be present.
        XCTAssertEqual(count, 10, "Split count does not match expected value.")
    }
}

//
//  SplitsStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitsStorageTest: XCTestCase {

    let dummyChangeNumber: Int64 = 100
    let dummyUpdateTimestamp: Int64 = 1000
    let dummyQs = "dummy=1"
    let kTestCount = 10


    var persistentStorage: PersistentSplitsStorageStub!
    var splitsStorage: SplitsStorage!

    override func setUp() {
        persistentStorage = PersistentSplitsStorageStub()
        splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistentStorage)
    }

    func testNoLocalLoaded() {
        persistentStorage.snapshot = dummySnapshot()
        let splits = splitsStorage.getAll()
        let changeNumber = splitsStorage.changeNumber
        let updateTimestamp = splitsStorage.updateTimestamp

        XCTAssertEqual(0, splits.count)
        XCTAssertEqual(-1,changeNumber)
        XCTAssertEqual(-1, updateTimestamp)
    }

    func testLoaded() {

        persistentStorage.snapshot = getTestSnapshot()

        splitsStorage.loadLocal()

        let splits = splitsStorage.getAll()
        let changeNumber = splitsStorage.changeNumber
        let updateTimestamp = splitsStorage.updateTimestamp
        let qs = splitsStorage.splitsFilterQueryString

        XCTAssertEqual(kTestCount, splits.count)
        XCTAssertEqual(dummyChangeNumber,changeNumber)
        XCTAssertEqual(dummyUpdateTimestamp, updateTimestamp)
        XCTAssertEqual(dummyQs, qs)
    }

    func testUpdateSplits() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let processedChange = ProcessedSplitChange(activeSplits: [newSplit(name: "added"), newSplit(name: "added1")],
                                                   archivedSplits: [newSplit(name: "s1", status: .archived)],
                                                   changeNumber: 999, updateTimestamp: 888)

        splitsStorage.update(splitChange: processedChange)

        let splits = splitsStorage.getAll()
        let changeNumber = splitsStorage.changeNumber
        let updateTimestamp = splitsStorage.updateTimestamp

        XCTAssertEqual(11, splits.count)
        XCTAssertEqual(999,changeNumber)
        XCTAssertEqual(888, updateTimestamp)
        XCTAssertEqual(0, splits.keys.filter { return $0 == "s1"}.count)
        XCTAssertEqual(1, splits.keys.filter { return $0 == "added"}.count)
        XCTAssertEqual(1, splits.keys.filter { return $0 == "added1"}.count)
        XCTAssertTrue(persistentStorage.updateCalled)
    }

    func testUpdateEmptySplits() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let processedChange = ProcessedSplitChange(activeSplits: [],
                                                   archivedSplits: [],
                                                   changeNumber: 999, updateTimestamp: 888)

        splitsStorage.update(splitChange: processedChange)

        let splits = splitsStorage.getAll()
        let changeNumber = splitsStorage.changeNumber
        let updateTimestamp = splitsStorage.updateTimestamp

        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(999,changeNumber)
        XCTAssertEqual(888, updateTimestamp)
        XCTAssertTrue(persistentStorage.updateCalled)
    }

    func testGetMany() {
        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let splits = splitsStorage.getMany(splits: ["s1", "s9"])

        XCTAssertEqual(2, splits.count)
        XCTAssertEqual(1, splits.keys.filter { return $0 == "s1"}.count)
        XCTAssertEqual(1, splits.keys.filter { return $0 == "s9"}.count)
    }

    func testGetManyEmpty() {
        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let splits = splitsStorage.getMany(splits: [])

        XCTAssertEqual(0, splits.count)
    }

    func testUpdatedSplitTrafficType() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let s1 = newSplit(name: "s1", status: .active, trafficType: "tt")

        let s2 = newSplit(name: "s2", status: .active, trafficType: "mytt")
        let s2ar = newSplit(name: "s2", status: .archived, trafficType: "mytt")

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                               archivedSplits: [s2ar],
                                                               changeNumber: 1, updateTimestamp: 1))

        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "tt"))
        XCTAssertFalse(splitsStorage.isValidTrafficType(name: "mytt"))
    }

    func testChangedTrafficTypeForSplit() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let s1t1 = newSplit(name: "n_s1", status: .active, trafficType: "tt")
        let s1t2 = newSplit(name: "n_s1", status: .active, trafficType: "mytt")

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        XCTAssertFalse(splitsStorage.isValidTrafficType(name: "tt"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "mytt"))
    }

    func testExistingChangedTrafficTypeForSplit() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let s0 = newSplit(name: "n_s0", status: .active, trafficType: "tt")
        let s1t1 = newSplit(name: "n_s1", status: .active, trafficType: "tt")
        let s1t2 = newSplit(name: "n_s1", status: .active, trafficType: "mytt")

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s0],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "tt"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "mytt"))
    }

    func testUpdateSplit() {
        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()
        let s0 = newSplit(name: "s0", status: .active, trafficType: "ttupdated")
        splitsStorage.updateWithoutChecks(split: s0)
        let updatedSplit = splitsStorage.get(name: "s0")

        XCTAssertTrue(persistentStorage.updateSplitCalled)
        XCTAssertEqual("ttupdated", updatedSplit?.trafficTypeName ?? "")
    }


    private func dummySnapshot() -> SplitsSnapshot {
        return SplitsSnapshot(changeNumber: dummyChangeNumber, splits: [],
                              updateTimestamp: dummyUpdateTimestamp, splitsFilterQueryString: dummyQs)
    }

    private func getTestSnapshot() -> SplitsSnapshot {
        var splits = [Split]()
        for i in 0..<kTestCount {
            let split = Split()
            split.name = "s\(i)"
            split.trafficTypeName = "t1"
            split.status = .active

            splits.append(split)
        }

        return SplitsSnapshot(changeNumber: dummyChangeNumber, splits: splits,
                                                    updateTimestamp: dummyUpdateTimestamp,
                                                    splitsFilterQueryString: dummyQs)
    }

    private func newSplit(name: String, status: Status = .active, trafficType: String = "t1") -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }

    override func tearDown() {

    }
}

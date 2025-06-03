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
    let kTestCount = 10
    var flagSetsCache: FlagSetsCacheMock!

    var persistentStorage: PersistentSplitsStorageStub!
    var splitsStorage: SplitsStorage!

    override func setUp() {
        persistentStorage = PersistentSplitsStorageStub()
        flagSetsCache = FlagSetsCacheMock()
        splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistentStorage, flagSetsCache: flagSetsCache)
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

        XCTAssertEqual(kTestCount, splits.count)
        XCTAssertEqual(dummyChangeNumber,changeNumber)
        XCTAssertEqual(dummyUpdateTimestamp, updateTimestamp)
    }

    func testUpdateSplits() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let processedChange = ProcessedSplitChange(activeSplits: [newSplit(name: "added"), newSplit(name: "added1")],
                                                   archivedSplits: [newSplit(name: "s1", status: .archived)],
                                                   changeNumber: 999, updateTimestamp: 888)

        _ = splitsStorage.update(splitChange: processedChange)

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
    
    func testFetchTwiceParseOnce() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()
        
        let split = newSplit(name: "TwiceTestSplit")
        XCTAssertFalse(split.isCompletelyParsed, "A new Split shouln't be parsed yet")

        let processedChange = ProcessedSplitChange(activeSplits: [split],
                                                   archivedSplits: [],
                                                   changeNumber: 999, updateTimestamp: 888)

        _ = splitsStorage.update(splitChange: processedChange)
        let splitGet = splitsStorage.get(name: "TwiceTestSplit")
        
        XCTAssert(splitGet!.isCompletelyParsed, "After getting it once, the Split it should be parsed")
    }
    
    func testFetch() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()
        
        let split = newSplit(name: "TwiceTestSplit")
        XCTAssertFalse(split.isCompletelyParsed)

        let processedChange = ProcessedSplitChange(activeSplits: [split],
                                                   archivedSplits: [],
                                                   changeNumber: 999, updateTimestamp: 888)

        _ = splitsStorage.update(splitChange: processedChange)
        _ = splitsStorage.get(name: "TwiceTestSplit")
        XCTAssertNotNil(splitsStorage.getAll()["twicetestsplit"])
    }

    func testUpdateEmptySplits() {

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        let processedChange = ProcessedSplitChange(activeSplits: [],
                                                   archivedSplits: [],
                                                   changeNumber: 999, updateTimestamp: 888)

        _ = splitsStorage.update(splitChange: processedChange)

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

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s2],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
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

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                               archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t2],
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

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s0],
                                                                   archivedSplits: [],
                                                                   changeNumber: 1, updateTimestamp: 1))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                                   archivedSplits: [],
                                                                   changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t1],
                                                                   archivedSplits: [],
                                                                   changeNumber: 1, updateTimestamp: 1))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [s1t2],
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

    func testUpdateBySetsFilter() {

        splitsStorage.update(bySetsFilter: SplitFilter(type: .bySet, values: ["set1", "set2"]))

        let updatedFilter = persistentStorage.lastBySetSplitFilter
        XCTAssertTrue(persistentStorage.updateBySetsFilterCalled)
        XCTAssertEqual(SplitFilter.FilterType.bySet, updatedFilter?.type)
        XCTAssertEqual(["set1", "set2"], updatedFilter?.values.sorted())
    }

    func testUpdateResult() {

        let flagSetsCache = FlagSetsCacheMock()
        flagSetsCache.setsInFilter = ["set1", "set2", "set3"]
        splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistentStorage, flagSetsCache: flagSetsCache)
        persistentStorage.snapshot = getTestSnapshot(count: 3,
                                                     sets: [
                                                        ["set1", "set2"],
                                                        ["set1"],
                                                        ["set3"]
                                                     ]
        )

        splitsStorage.loadLocal()

        var processedChange = ProcessedSplitChange(activeSplits: [],
                                                   archivedSplits: [newSplit(name: "s1", status: .archived, sets: ["set1"])],
                                                   changeNumber: 999, updateTimestamp: 888)

        let resultOnDelete = splitsStorage.update(splitChange: processedChange)

        processedChange = ProcessedSplitChange(activeSplits: [newSplit(name: "s1", status: .archived, sets: ["set1"])],
                                               archivedSplits: [],
                                               changeNumber: 9999, updateTimestamp: 8888)

        let resultOnAdd = splitsStorage.update(splitChange: processedChange)


        processedChange = ProcessedSplitChange(activeSplits: [],
                                               archivedSplits: [],
                                               changeNumber: 99999, updateTimestamp: 88888)

        let resultOnNoChange = splitsStorage.update(splitChange: processedChange)

        XCTAssertTrue(resultOnDelete)
        XCTAssertTrue(resultOnAdd)
        XCTAssertFalse(resultOnNoChange)
    }

    func testUnsupportedMatcherHasDefaultCondition() {
        let split = unsupportedMatcherSplit()

        persistentStorage.snapshot = getTestSnapshot()
        splitsStorage.loadLocal()

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split],
                                                                   archivedSplits: [],
                                                                   changeNumber: 1, updateTimestamp: 1))
        let splitFromStorage = splitsStorage.get(name: "feature_flag_for_test")
        let condition = splitFromStorage!.conditions![0]
        XCTAssertTrue(splitFromStorage != nil)
        XCTAssertTrue(splitFromStorage?.conditions?.count == 1)
        XCTAssertTrue(condition.conditionType == ConditionType.whitelist)
        XCTAssertTrue(condition.label == "targeting rule type unsupported by sdk")
        XCTAssertTrue(condition.partitions?.count == 1)
        XCTAssertTrue(condition.partitions?[0].size == 100)
        XCTAssertTrue(condition.partitions?[0].treatment == "control")
        XCTAssertTrue(condition.matcherGroup?.matcherCombiner == .and)
    }

    private func getTestSnapshot(count: Int = 10, sets: [[String]]? = nil) -> SplitsSnapshot {
        var splits = [Split]()
        for i in 0..<count {
            let split = Split(name: "s\(i)", trafficType: "t1", status: .active, sets: nil, json: "")
            split.isCompletelyParsed = true
            if let sets = sets {
                sets.forEach { fset in
                    split.sets = fset.asSet()
                }
            }
            splits.append(split)
        }

        return SplitsSnapshot(changeNumber: dummyChangeNumber, splits: splits,
                              updateTimestamp: dummyUpdateTimestamp)
    }

    private func dummySnapshot() -> SplitsSnapshot {
        return SplitsSnapshot(changeNumber: dummyChangeNumber, splits: [],
                              updateTimestamp: dummyUpdateTimestamp)
    }

    private func newSplit(name: String,
                          status: Status = .active,
                          trafficType: String = "t1",
                          sets: [String]? = nil) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: trafficType)
        split.status = status
        if let sets = sets {
            split.sets = sets.asSet()
        }
        return split
    }

    private func unsupportedMatcherSplit() -> Split {
       return Split(name: "feature_flag_for_test", trafficType: "user",
                    status: Status.active, sets: [], json: SplitTestHelper.getUnsupportedMatcherSplitJson(sourceClass: self)!)
    }
}

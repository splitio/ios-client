//
//  SplitsStorageTrafficTypesTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest

@testable import Split

class SplitsStorageTrafficTypesTests: XCTestCase {
    
    var splitsStorage: SplitsStorage!
    var flagSetsCache: FlagSetsCacheMock!

    override func setUp() {
        
        var splits = [Split]()
        for i in 0..<5 {
            splits.append(newSplit(name: "s\(i)", trafficType: "trafficType\(i)"))
        }

        let persistent = PersistentSplitsStorageStub()
        flagSetsCache = FlagSetsCacheMock()

        persistent.snapshot = SplitsSnapshot(changeNumber: 1, splits: splits, updateTimestamp: 100)
        splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistent, flagSetsCache: flagSetsCache)
        splitsStorage.loadLocal(forceReparse: false)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testInitialtrafficTypes(){
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "trafficType0"), "Initial trafficTypes - trafficType0 should be in splitsStorage")
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "trafficType1"), "Initial trafficTypes - trafficType1 should be in splitsStorage")
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "trafficType2"), "Initial trafficTypes - trafficType2 should be in splitsStorage")
        XCTAssertTrue(splitsStorage.isValidTrafficType(name: "trafficType3"), "Initial trafficTypes - trafficType3 should be in splitsStorage")
    }
    
    func testRemove2TrafficTypes() {
        var splitsAr = [Split]()
        splitsAr.append(newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        splitsAr.append(newSplit(name: "s1", trafficType: "trafficType1", status: .archived))
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                                   archivedSplits: splitsAr,
                                                                   changeNumber: 200, 
                                                                   updateTimestamp: 200))

        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "trafficType0"))
        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "trafficType1"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType2"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalActive() {
        var splitsAc = [Split]()
        var splitsAr = [Split]()
        splitsAr.append(newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        splitsAc.append(newSplit(name: "s01", trafficType: "trafficType0", status: .active))
        splitsAr.append(newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        splitsAc.append(newSplit(name: "s02", trafficType: "trafficType0", status: .active))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splitsAc,
                                                                   archivedSplits: splitsAr,
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))

        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType0"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType1"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType2"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalArchived() {
        var splits = [Split]()
        splits.append(newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s01", trafficType: "trafficType0", status: .active))
        splits.append(newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s02", trafficType: "trafficType0", status: .active))
        splits.append(newSplit(name: "s02", trafficType: "trafficType0", status: .archived))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                                   archivedSplits: splits,
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))

        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "trafficType0"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType1"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType2"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType3"))
    }
    
    func testOverflowArchived() {
        var splits = [Split]()
        splits.append(newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s02", trafficType: "trafficType0", status: .archived))
        splits.append(newSplit(name: "s02", trafficType: "trafficType0", status: .archived))

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [],
                                                                   archivedSplits: splits,
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))

        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "trafficType0"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType1"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType2"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "trafficType3"))
    }
    
    func testUpdatedSplitTrafficType() {
        
        let s1 = newSplit(name: "n_s0", trafficType: "tt", status: .active)
        let s2 = newSplit(name: "n_s2", trafficType: "mytt", status: .active)
        let s2ar = newSplit(name: "n_s2", trafficType: "mytt", status: .archived)

        var splits = [Split]()
        splits.append(s1)
        splits.append(s2)
        splits.append(s2)
        splits.append(s2)

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits,
                                                                   archivedSplits: [s2ar],
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))

        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "tt"))
        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "mytt"))
    }
    
    
    func testChangedTrafficTypeForSplit() {
        // Testing remove a feature flag and recreate it with other tt
        let splitName = "n_s2"
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .active)
        var splits = [Split]()
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t2)
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits,
                                                                   archivedSplits: [],
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))
        XCTAssertFalse(splitsStorage.isValidTrafficType(name:  "tt"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "mytt"))
    }
    
    func testExistingChangedTrafficTypeForSplit() {
        let splitName = "n_s2"
        let s1 = newSplit(name: "n_s1", trafficType: "tt", status: .active)
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .active)

        var splits = [Split]()
        splits.append(s1)
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t1)
        splits.append(s2t2)

        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits,
                                                                   archivedSplits: [],
                                                                   changeNumber: 200,
                                                                   updateTimestamp: 200))

        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "tt"))
        XCTAssertTrue(splitsStorage.isValidTrafficType(name:  "mytt"))
    }
 
    private func newSplit(name: String, trafficType: String, status: Status = .active) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: trafficType)
        split.status = status
        split.isCompletelyParsed = true
        return split
    }
}

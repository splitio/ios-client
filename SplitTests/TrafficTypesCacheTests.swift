//
//  TrafficTypesCacheTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest

@testable import Split

class TrafficTypesCacheTests: XCTestCase {
    
    var cache: TrafficTypesCache!

    override func setUp() {
        let types = ["traffictype0", "traffictype1", "traffictype2", "traffictype3"]
        let statusList = [Status.Active, Status.Active, Status.Active, Status.Archived]
        let splits = createSplits(trafficTypes: types, status: statusList)
        cache = InMemoryTrafficTypesCache(splits: splits)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testInitialtrafficTypes(){
        XCTAssertEqual(cache.getAll().count, 3, "Initial trafficTypes count check")
        XCTAssertTrue(cache.contains(name: "traffictype0"), "Initial trafficTypes - traffictype0 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype1"), "Initial trafficTypes - traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "Initial trafficTypes - traffictype2 should be in cache")
        XCTAssertFalse(cache.contains(name: "traffictype3"), "Initial trafficTypes - traffictype2 should be in cache")
    }
    
    func testSet4ActiveTraffictypes() {
        let types = ["trafficType0", "trafficType1", "trafficType2", "traffictype3"]
        let splits = createSplits(trafficTypes: types)
        cache.set(from: splits)
        XCTAssertEqual(cache.getAll().count, 4)
        XCTAssertTrue(cache.contains(name: "traffictype0"), "traffictype0 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype1"), "traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "traffictype2 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype3"), "traffictype3 should be in cache")
    }
    
    func testSet4From8TrafficTypes() {
        let types = ["trafficType0", "trafficType1", "trafficType2", "traffictype3", "traffictype4", "traffictype5", "traffictype6", "traffictype7"]
        let statusList: [Status] = [.Archived, .Archived, .Active, .Active, .Active, .Archived, .Archived, .Active]
        let splits = createSplits(trafficTypes: types, status: statusList)
        cache.set(from: splits)
        XCTAssertEqual(cache.getAll().count, 4, "Added 1 trafficTypes - count")
        XCTAssertFalse(cache.contains(name: "traffictype0"), "traffictype0 should be in cache")
        XCTAssertFalse(cache.contains(name: "traffictype1"), "traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "traffictype2 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype3"), "traffictype3 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype4"), "traffictype4 should be in cache")
        XCTAssertFalse(cache.contains(name: "traffictype5"), "traffictype5 should be in cache")
        XCTAssertFalse(cache.contains(name: "traffictype6"), "traffictype6 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype7"), "traffictype7 should be in cache")
    }
    
    func testTwoRepeatedWithTraffictype() {
        let types = ["trafficType0", "trafficType1", "trafficType0", "traffictype0", "traffictype1", "traffictype2", "traffictype3", "traffictype2", "traffictype4", "traffictype5"]
        let statusList: [Status] = [.Archived, .Archived, .Active, .Active, .Active, .Active, .Active, .Archived, .Active, .Archived]
        let splits = createSplits(trafficTypes: types, status: statusList)
        cache.set(from: splits)
        XCTAssertEqual(cache.getAll().count, 5, "Removed 1 traffictype - count")
        XCTAssertTrue(cache.contains(name: "traffictype0"))
        XCTAssertTrue(cache.contains(name: "traffictype1"))
        XCTAssertTrue(cache.contains(name: "traffictype2"))
        XCTAssertTrue(cache.contains(name: "traffictype3"))
        XCTAssertTrue(cache.contains(name: "traffictype4"))
        XCTAssertFalse(cache.contains(name: "traffictype5"))
    }
    
    func testRemoveTrafficTypes() {
        let types = ["trafficType0", "trafficType0", "trafficType0", "traffictype0", "traffictype1", "traffictype2"]
        let statusList: [Status] = [.Active, .Archived, .Archived, .Archived, .Active, .Active]
        let splits = createSplits(trafficTypes: types, status: statusList)
        cache.set(from: splits)
        XCTAssertEqual(cache.getAll().count, 3, "Removed 2 trafficTypes - count")
        XCTAssertTrue(cache.contains(name: "traffictype0"), "traffictype0 should not be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype1"), "traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "traffictype2 should not be in cache")
    }
    
    func test1ArchivedTrafficTypes() {
        let types = ["trafficType0", "trafficType0", "trafficType0", "traffictype0", "traffictype1", "traffictype2"]
        let statusList: [Status] = [.Archived, .Archived, .Archived, .Archived, .Active, .Active]
        let splits = createSplits(trafficTypes: types, status: statusList)
        cache.set(from: splits)
        XCTAssertEqual(cache.getAll().count, 2, "Removed 2 trafficTypes - count")
        XCTAssertFalse(cache.contains(name: "traffictype0"), "traffictype0 should not be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype1"), "traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "traffictype2 should not be in cache")
    }
    
    private func createSplits(trafficTypes: [String], status: [Status]? = nil) -> [Split] {
        var splits = [Split]()

        for (index, trafficType) in trafficTypes.enumerated() {
            splits.append(newSplit(trafficType: trafficType, status: status?[index] ?? .Active))
        }
        return splits
    }
    
    private func newSplit(trafficType: String, status: Status = .Active) -> Split {
        let split = Split()
        split.name = UUID().uuidString
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
    

}

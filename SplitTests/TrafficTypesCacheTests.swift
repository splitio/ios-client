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
        let splits = [
            newSplit(name: "s0", trafficType: "trafficType0"),
            newSplit(name: "s1", trafficType: "trafficType1"),
            newSplit(name: "s2", trafficType: "trafficType2"),
            newSplit(name: "s3", trafficType: "trafficType3")
        ]
        cache = InMemoryTrafficTypesCache()
        cache.update(from: splits)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testInitialtrafficTypes(){
        XCTAssertTrue(cache.contains(name: "traffictype0"), "Initial trafficTypes - traffictype0 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype1"), "Initial trafficTypes - traffictype1 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype2"), "Initial trafficTypes - traffictype2 should be in cache")
        XCTAssertTrue(cache.contains(name: "traffictype3"), "Initial trafficTypes - traffictype3 should be in cache")
    }
    
    func testRemove2TrafficTypes() {
        let splits = [
            newSplit(name: "s0", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s1", trafficType: "trafficType1", status: .Archived)
        ]
        cache.update(from: splits)
        XCTAssertFalse(cache.contains(name: "traffictype0"))
        XCTAssertFalse(cache.contains(name: "traffictype1"))
        XCTAssertTrue(cache.contains(name: "traffictype2"))
        XCTAssertTrue(cache.contains(name: "traffictype3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalActive() {
        let splits = [
            newSplit(name: "s0", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Active),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s02", trafficType: "trafficType0", status: .Active),
        ]
        cache.update(from: splits)
        XCTAssertTrue(cache.contains(name: "traffictype0"))
        XCTAssertTrue(cache.contains(name: "traffictype1"))
        XCTAssertTrue(cache.contains(name: "traffictype2"))
        XCTAssertTrue(cache.contains(name: "traffictype3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalArchived() {
        let splits = [
            newSplit(name: "s0", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Active),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s02", trafficType: "trafficType0", status: .Active),
            newSplit(name: "s02", trafficType: "trafficType0", status: .Archived),
            ]
        cache.update(from: splits)
        XCTAssertFalse(cache.contains(name: "traffictype0"))
        XCTAssertTrue(cache.contains(name: "traffictype1"))
        XCTAssertTrue(cache.contains(name: "traffictype2"))
        XCTAssertTrue(cache.contains(name: "traffictype3"))
    }
    
    func testOverflowArchived() {
        let splits = [
            newSplit(name: "s0", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s01", trafficType: "trafficType0", status: .Archived),
            newSplit(name: "s02", trafficType: "trafficType0", status: .Active),
            newSplit(name: "s02", trafficType: "trafficType0", status: .Archived),
            ]
        cache.update(from: splits)
        XCTAssertFalse(cache.contains(name: "traffictype0"))
        XCTAssertTrue(cache.contains(name: "traffictype1"))
        XCTAssertTrue(cache.contains(name: "traffictype2"))
        XCTAssertTrue(cache.contains(name: "traffictype3"))
    }
    
    
    private func newSplit(name: String, trafficType: String, status: Status = .Active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
    

}

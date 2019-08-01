//
//  InMemorySplitCacheTrafficTypesTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest

@testable import Split

class InMemorySplitCacheTrafficTypesTests: XCTestCase {
    
    var cache: SplitCacheProtocol!

    override func setUp() {
        
        var splits = [String:Split]()
        for i in 0..<5 {
            splits["s\(i)"] = newSplit(name: "s\(i)", trafficType: "trafficType\(i)")
        }
        cache = InMemorySplitCache(splits: splits, changeNumber: 1)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testInitialtrafficTypes(){
        XCTAssertTrue(cache.exists(trafficType: "traffictype0"), "Initial trafficTypes - traffictype0 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "traffictype1"), "Initial trafficTypes - traffictype1 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "traffictype2"), "Initial trafficTypes - traffictype2 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "traffictype3"), "Initial trafficTypes - traffictype3 should be in cache")
    }
    
    func testRemove2TrafficTypes() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s1", split: newSplit(name: "s1", trafficType: "trafficType1", status: .Archived))
        XCTAssertFalse(cache.exists(trafficType: "traffictype0"))
        XCTAssertFalse(cache.exists(trafficType: "traffictype1"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype2"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalActive() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Active))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .Active))
        XCTAssertTrue(cache.exists(trafficType: "traffictype0"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype1"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype2"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalArchived() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Active))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .Active))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .Archived))
        XCTAssertFalse(cache.exists(trafficType: "traffictype0"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype1"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype2"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype3"))
    }
    
    func testOverflowArchived() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .Archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .Archived))
    
        XCTAssertFalse(cache.exists(trafficType: "traffictype0"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype1"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype2"))
        XCTAssertTrue(cache.exists(trafficType: "traffictype3"))
    }
    
    func testUpdatedSplitTrafficType() {
        
        let s1 = newSplit(name: "n_s0", trafficType: "tt", status: .Active)
        let s2 = newSplit(name: "n_s2", trafficType: "mytt", status: .Active)
        let s2ar = newSplit(name: "n_s2", trafficType: "mytt", status: .Archived)

        cache.addSplit(splitName: s1.name!, split: s1)
        cache.addSplit(splitName: s2.name!, split: s2)
        cache.addSplit(splitName: s2.name!, split: s2)
        cache.addSplit(splitName: s2.name!, split: s2)
        cache.addSplit(splitName: s2ar.name!, split: s2ar)
        
        XCTAssertTrue(cache.exists(trafficType: "tt"))
        XCTAssertFalse(cache.exists(trafficType: "mytt"))
    }
    
    
    func testChangedTrafficTypeForSplit() {
        // Testing remove split and recreate it with other tt
        let splitName = "n_s2"
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .Active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .Active)
        
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t2)
        
        XCTAssertFalse(cache.exists(trafficType: "tt"))
        XCTAssertTrue(cache.exists(trafficType: "mytt"))
    }
    
    func testExistingChangedTrafficTypeForSplit() {
        let splitName = "n_s2"
        let s1 = newSplit(name: "n_s1", trafficType: "tt", status: .Active)
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .Active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .Active)
        
        cache.addSplit(splitName: s1.name!, split: s1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t2)
        
        XCTAssertTrue(cache.exists(trafficType: "tt"))
        XCTAssertTrue(cache.exists(trafficType: "mytt"))
    }
 
    private func newSplit(name: String, trafficType: String, status: Status = .Active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
    

}

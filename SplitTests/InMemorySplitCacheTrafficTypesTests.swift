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
        XCTAssertTrue(cache.exists(trafficType: "trafficType0"), "Initial trafficTypes - trafficType0 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "trafficType1"), "Initial trafficTypes - trafficType1 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "trafficType2"), "Initial trafficTypes - trafficType2 should be in cache")
        XCTAssertTrue(cache.exists(trafficType: "trafficType3"), "Initial trafficTypes - trafficType3 should be in cache")
    }
    
    func testRemove2TrafficTypes() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s1", split: newSplit(name: "s1", trafficType: "trafficType1", status: .archived))
        XCTAssertFalse(cache.exists(trafficType: "trafficType0"))
        XCTAssertFalse(cache.exists(trafficType: "trafficType1"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType2"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalActive() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .active))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .active))
        XCTAssertTrue(cache.exists(trafficType: "trafficType0"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType1"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType2"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType3"))
    }
    
    func testSeveralTrafficTypeUpdatesFinalArchived() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .active))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .active))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .archived))
        XCTAssertFalse(cache.exists(trafficType: "trafficType0"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType1"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType2"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType3"))
    }
    
    func testOverflowArchived() {
        cache.addSplit(splitName: "s0", split: newSplit(name: "s0", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s01", split: newSplit(name: "s01", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .archived))
        cache.addSplit(splitName: "s02", split: newSplit(name: "s02", trafficType: "trafficType0", status: .archived))
    
        XCTAssertFalse(cache.exists(trafficType: "trafficType0"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType1"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType2"))
        XCTAssertTrue(cache.exists(trafficType: "trafficType3"))
    }
    
    func testUpdatedSplitTrafficType() {
        
        let s1 = newSplit(name: "n_s0", trafficType: "tt", status: .active)
        let s2 = newSplit(name: "n_s2", trafficType: "mytt", status: .active)
        let s2ar = newSplit(name: "n_s2", trafficType: "mytt", status: .archived)

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
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .active)
        
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
        let s1 = newSplit(name: "n_s1", trafficType: "tt", status: .active)
        let s2t1 = newSplit(name: splitName, trafficType: "tt", status: .active)
        let s2t2 = newSplit(name: splitName, trafficType: "mytt", status: .active)
        
        cache.addSplit(splitName: s1.name!, split: s1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t1)
        cache.addSplit(splitName: splitName, split: s2t2)
        
        XCTAssertTrue(cache.exists(trafficType: "tt"))
        XCTAssertTrue(cache.exists(trafficType: "mytt"))
    }
 
    private func newSplit(name: String, trafficType: String, status: Status = .active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
}

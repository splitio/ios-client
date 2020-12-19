//
//  InMemorySplitCacheTests.swift
//  Split
//
//  Created by Brian Sztamfater on 5/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class InMemorySplitCacheTests: XCTestCase {
    
    var splitCache: InMemorySplitCache!
    
    override func setUp() {
        splitCache = InMemorySplitCache()
        let jsonSplit = "{\"name\":\"test\", \"status\":\"active\"}"
        let split1 = try? JSON.encodeFrom(json: jsonSplit, to: Split.self)
        splitCache.addSplit(splitName: split1!.name!, split: split1!)
        
        let jsonSplit2 = "{\"name\":\"test2\", \"status\":\"archived\"}"
        let split2 = try? JSON.encodeFrom(json: jsonSplit2, to: Split.self)
        splitCache.addSplit(splitName: split2!.name!, split: split2!)
    }
    
    override func tearDown() {
    }
    
    func testSaveSplit() {
        let cachedSplit = splitCache.getSplit(splitName: "test")
        XCTAssertNotNil(cachedSplit, "Cached split should not be nil")
        XCTAssertEqual(cachedSplit!.name!, "test", "Split name should be 'Test'")
        XCTAssertEqual(cachedSplit!.status, Status.active, "Split status should be active")
        XCTAssertNil(cachedSplit!.conditions, "Split conditions should be nil")
        XCTAssertNil(cachedSplit!.killed, "Split should not be killed")
    }
    
    func testGetAllSplits() {
        let allCachedSplits = splitCache.getAllSplits()
        XCTAssertNotNil(allCachedSplits, "Cached splits should not be nil")
        XCTAssertEqual(allCachedSplits.count, 2, "Cached splits should be 2")
        XCTAssertNotNil(allCachedSplits[0], "First Cached split should not be nil")
    }
    
    func testClearCache() {
        splitCache.clear()
        let allCachedSplits = splitCache.getAllSplits()
        XCTAssertNotNil(allCachedSplits, "Cleared cached splits should not be nil")
        XCTAssertEqual(allCachedSplits.count, 0, "Cleared cached splits should be empty")
        
    }
    
    
}

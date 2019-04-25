//
//  SplitsCacheTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest

@testable import Split

class SplitCacheTests: XCTestCase {
    
    var splitCache: SplitCacheProtocol!
    let initialChangeNumber: Int64 = 44

    override func setUp() {
        let fileContent = initialSplitFile()
        let fileStorage = FileStorageStub()
        fileStorage.write(fileName: "SPLITIO.splits", content: fileContent)
        splitCache = SplitCache(fileStorage: fileStorage)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitialSplits(){
        XCTAssertEqual(splitCache.getSplits().count, 3, "Initial splits count check")
        XCTAssertNotNil(splitCache.getSplit(splitName: "split0"), "Initial splits - split0 should be in cache")
        XCTAssertNotNil(splitCache.getSplit(splitName: "split1"), "Initial splits - split1 should be in cache")
        XCTAssertNotNil(splitCache.getSplit(splitName: "split2"), "Initial splits - split2 should be in cache")
    }
    
    func testAddOneSplit() {
        let splitName = "split3"
        splitCache.addSplit(splitName: splitName, split: createSplit(name: splitName))
        XCTAssertEqual(splitCache.getSplits().count, 4, "Added 1 splits - count")
        XCTAssertNotNil(splitCache.getSplit(splitName: splitName), "\(splitName) should be in cache")
    }
    
    func testAddTwoSplits() {
        let splitName3 = "split3"
        let splitName4 = "split4"
        splitCache.addSplit(splitName: splitName3, split: createSplit(name: splitName3))
        
        splitCache.addSplit(splitName: splitName4, split: createSplit(name: splitName4))
        XCTAssertEqual(splitCache.getSplits().count, 5, "Added 1 splits - count")
        XCTAssertNotNil(splitCache.getSplit(splitName: splitName3), "\(splitName3) should be in cache")
        XCTAssertNotNil(splitCache.getSplit(splitName: splitName4), "\(splitName4) should be in cache")
    }
    
    func testRemoveOneSplit() {
        let splitName2 = "split2"
        splitCache.removeSplit(splitName: splitName2)
        XCTAssertEqual(splitCache.getSplits().count, 2, "Removed 1 split - count")
        XCTAssertNotNil(splitCache.getSplit(splitName: "split0"), "split0 should be in cache")
        XCTAssertNil(splitCache.getSplit(splitName: splitName2), "\(splitName2) should no be in cache")
    }
    
    func testRemoveTwoSplits() {
        let splitName1 = "split1"
        let splitName2 = "split2"
        splitCache.removeSplit(splitName: splitName1)
        splitCache.removeSplit(splitName: splitName2)
        XCTAssertEqual(splitCache.getSplits().count, 1, "Removed 2 splits - count")
        XCTAssertNotNil(splitCache.getSplit(splitName: "split0"), "split0 should be in cache")
        XCTAssertNil(splitCache.getSplit(splitName: splitName1), "\(splitName1) should not be in cache")
        XCTAssertNil(splitCache.getSplit(splitName: splitName2), "\(splitName2) should not be in cache")
    }
    
    func testInitialChangeNumber() {
        XCTAssertEqual(splitCache.getChangeNumber(), initialChangeNumber, "Change number should be \(initialChangeNumber)")
    }
    
    func testChangeNumberUpdate() {
        let newChangeNumber: Int64 = 50
        splitCache.setChangeNumber(newChangeNumber)
        XCTAssertEqual(splitCache.getChangeNumber(), newChangeNumber, "Change number should be \(initialChangeNumber)")
    }
    
    func createSplit(name: String) -> Split {
        let jsonSplit = "{\"name\":\"\(name)\", \"status\":\"active\"}"
        let split = try? JSON.encodeFrom(json: jsonSplit, to: Split.self)
        return split!
    }
    
    func initialSplitFile() -> String {
        return "{ \"changeNumber\":\(initialChangeNumber), \"splits\": {\"split0\": {\"name\":\"split0\", \"status\":\"active\"}, \"split1\": {\"name\":\"split1\", \"status\":\"active\"}, \"split2\": {\"name\":\"split2\", \"status\":\"active\"}}}"
    }

}

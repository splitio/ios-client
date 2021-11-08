//
//  MySegmentsDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsDaoTests: XCTestCase {
    
    var mySegmentsDao: MySegmentsDao!
    
    override func setUp() {
        let queue = DispatchQueue(label: "my segments dao test")
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
    }
    
    func testUpdateGet() {
        let userKey = "ukey"
        mySegmentsDao.update(userKey: userKey, segmentList: ["s1", "s2"])
        
        let mySegments = mySegmentsDao.getBy(userKey: userKey)
        
        XCTAssertEqual(2, mySegments.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s2" }.count)
    }
    
    func testGetInvalidKey() {
        let userKey = "ukey"
        
        let mySegments = mySegmentsDao.getBy(userKey: userKey)
        
        XCTAssertEqual(0, mySegments.count)
    }
    
    override func tearDown() {
    }
}


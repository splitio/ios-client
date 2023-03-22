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

class MySegmentsDaoTest: XCTestCase {
    
    var mySegmentsDao: MySegmentsDao!
    var mySegmentsDaoAes128Cbc: MySegmentsDao!
    
    override func setUp() {
        let apiKey = String(IntegrationHelper.dummyApiKey.suffix(ServiceConstants.aes128KeyLength))
        let queue = DispatchQueue(label: "my segments dao test")
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
        cipher: DefaultCipher(key: apiKey))
    }
    
    func testUpdateGetPlainText() {
        updateGet(dao: mySegmentsDao)
    }

    func testUpdateGetAes128Cbc() {
        updateGet(dao: mySegmentsDaoAes128Cbc)
    }

    func updateGet(dao: MySegmentsDao) {
        let userKey = "ukey"
        dao.update(userKey: userKey, segmentList: ["s1", "s2"])
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(2, mySegments.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s2" }.count)
    }

    func testGetInvalidKeyPlainText() {
        getInvalidKey(dao: mySegmentsDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        getInvalidKey(dao: mySegmentsDaoAes128Cbc)
    }

    func getInvalidKey(dao: MySegmentsDao) {
        let userKey = "ukey"
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(0, mySegments.count)
    }
}


//
//  OneKeyPersistentAttributesStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class OneKeyPersistentAttributesStorageTests: XCTestCase {
    
    var attributesStorage: OneKeyPersistentAttributesStorage!
    var attributesDao: AttributesDaoStub!
    let dummyKey = "dummyKey"
    
    override func setUp() {
        attributesDao = AttributesDaoStub()
        attributesStorage =
            DefaultOneKeyPersistentAttributesStorage(userKey: "dummyKey",
                                               database: SplitDatabaseStub(eventDao: EventDaoStub(),
                                                                           impressionDao: ImpressionDaoStub(),
                                                                           impressionsCountDao: ImpressionsCountDaoStub(),
                                                                           generalInfoDao: GeneralInfoDaoStub(),
                                                                           splitDao: SplitDaoStub(),
                                                                           mySegmentsDao: MySegmentsDaoStub(),
                                                                           attributesDao: attributesDao))
    }
    
    func  testSet() {
        attributesStorage.set(["att1": "se1",
                               "att2": true,
                               "att3": 1])
        
        let attributes = attributesDao.getBy(userKey: dummyKey)!
        
        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }
    
    func testAll() {
        attributesDao.attributes[dummyKey] = ["att1": "se1",
                                              "att2": true,
                                              "att3": 1]
        
        let attributes = attributesStorage.getAll()!
        
        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }

    func testClear() {
        attributesDao.attributes[dummyKey] = ["att1": "se1",
                                              "att2": true,
                                              "att3": 1]

        attributesStorage.clear()

        XCTAssertNil(attributesDao.attributes[dummyKey])
    }
    
    override func tearDown() {
    }
}


//
//  AttributesDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class AttributesDaoTests: XCTestCase {
    
    var attributesDao: AttributesDao!

    let attributes: [String: Any] = ["att1": "se1",
                                     "att2": true,
                                     "att3": 1]
    
    override func setUp() {
        let queue = DispatchQueue(label: "my attributes dao test")
        attributesDao = CoreDataAttributesDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
    }
    
    func testUpdateGet() {

        let userKey = "ukey"
        attributesDao.update(userKey: userKey, attributes: self.attributes)
        
        let attributes = attributesDao.getBy(userKey: userKey)!
        
        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }
    
    func testGetInvalidKey() {
        let userKey = "ukey"
        
        let attributes = attributesDao.getBy(userKey: userKey)
        
        XCTAssertNil(attributes)
    }

    func testRemoveAll() {

        let userKey = "ukey"
        attributesDao.update(userKey: userKey, attributes: self.attributes)

        let attributes = attributesDao.getBy(userKey: userKey)!

        attributesDao.update(userKey: userKey, attributes: nil)

        let attributesCleared = attributesDao.getBy(userKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertNil(attributesCleared)
    }
    
    override func tearDown() {
    }
}


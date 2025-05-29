//
//  PersistentAttributesStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 04-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PersistentAttributesStorageTests: XCTestCase {
    var attributesStorage: PersistentAttributesStorage!
    var attributesDao: AttributesDaoStub!
    let dummyKey = "dummyKey"
    let dummyAttributes: [String: Any] = [
        "att1": "se1",
        "att2": true,
        "att3": 1,
    ]
    let otherKey = "otherKey"
    let otherAttributes: [String: Any] = ["oatt1": "ot1"]

    override func setUp() {
        attributesDao = AttributesDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.attributesDao = attributesDao
        attributesStorage =
            DefaultPersistentAttributesStorage(database: SplitDatabaseStub(daoProvider: daoProvider))
    }

    func testSet() {
        attributesStorage.set(dummyAttributes, forKey: dummyKey)

        let attributes = attributesDao.getBy(userKey: dummyKey)
        let otherAttributes = attributesDao.getBy(userKey: otherKey)

        XCTAssertEqual(3, attributes?.count ?? 0)
        XCTAssertEqual("se1", attributes?["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes?["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes?["att3"] as? Int ?? -1)
        XCTAssertNil(otherAttributes)
    }

    func testAll() {
        attributesDao.attributes[dummyKey] = dummyAttributes

        let attributes = attributesStorage.getAll(forKey: dummyKey)
        let otherAttributes = attributesStorage.getAll(forKey: otherKey)

        XCTAssertEqual(3, attributes?.count ?? 0)
        XCTAssertEqual("se1", attributes?["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes?["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes?["att3"] as? Int ?? -1)
        XCTAssertNil(otherAttributes)
    }

    func testClear() {
        attributesDao.attributes[dummyKey] = dummyAttributes
        attributesDao.attributes[otherKey] = otherAttributes

        attributesStorage.clear(forKey: dummyKey)
        let otherAttributes = attributesStorage.getAll(forKey: otherKey)

        XCTAssertNil(attributesDao.attributes[dummyKey])
        XCTAssertEqual(1, otherAttributes?.count ?? 0)
        XCTAssertEqual("ot1", otherAttributes?["oatt1"] as? String ?? "")
    }

    override func tearDown() {}
}

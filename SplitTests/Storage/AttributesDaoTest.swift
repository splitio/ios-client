//
//  AttributesDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class AttributesDaoTest: XCTestCase {
    var attributesDao: AttributesDao!
    var attributesDaoAes128Cbc: AttributesDao!

    let attributes: [String: Any] = [
        "att1": "se1",
        "att2": true,
        "att3": 1,
    ]

    override func setUp() {
        let queue = DispatchQueue(label: "my attributes dao test")
        attributesDao = CoreDataAttributesDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
        attributesDaoAes128Cbc = CoreDataAttributesDao(
            coreDataHelper: IntegrationCoreDataHelper.get(
                databaseName: "test",
                dispatchQueue: queue),
            cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
    }

    func testUpdateGetPlainText() {
        updateGet(dao: attributesDao)
    }

    func testUpdateGetAes128Cbc() {
        updateGet(dao: attributesDaoAes128Cbc)
    }

    func updateGet(dao: AttributesDao) {
        let userKey = "ukey"
        dao.update(userKey: userKey, attributes: self.attributes)

        let attributes = dao.getBy(userKey: userKey)!

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }

    func testGetInvalidKeyPlainText() {
        getInvalidKey(dao: attributesDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        getInvalidKey(dao: attributesDaoAes128Cbc)
    }

    func getInvalidKey(dao: AttributesDao) {
        let userKey = "ukey"

        let attributes = dao.getBy(userKey: userKey)

        XCTAssertNil(attributes)
    }

    func testRemoveAllPlainText() {
        removeAll(dao: attributesDao)
    }

    func testRemoveAllAes128Cbc() {
        removeAll(dao: attributesDaoAes128Cbc)
    }

    func removeAll(dao: AttributesDao) {
        let userKey = "ukey"
        dao.update(userKey: userKey, attributes: self.attributes)

        let attributes = dao.getBy(userKey: userKey)!

        dao.update(userKey: userKey, attributes: nil)

        let attributesCleared = dao.getBy(userKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertNil(attributesCleared)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "attributes dao test"))
        attributesDao = CoreDataAttributesDao(coreDataHelper: helper)
        attributesDaoAes128Cbc = CoreDataAttributesDao(
            coreDataHelper: helper,
            cipher: cipher)

        // Insert encrypted attributess
        attributesDaoAes128Cbc.update(userKey: IntegrationHelper.dummyUserKey, attributes: attributes)

        // load attributess and filter them by encrypted feature name
        let values = getBy(coreDataHelper: helper)

        let list = try? Json.decodeFrom(json: values.attributes ?? "", to: [String].self)

        XCTAssertNotEqual(IntegrationHelper.dummyUserKey, values.userKey)
        XCTAssertFalse(values.attributes?.contains("att1") ?? true)
        XCTAssertNil(list)
    }

    private func getBy(coreDataHelper: CoreDataHelper) -> (userKey: String?, attributes: String?) {
        var loadedKey: String?
        var loadedAttributes: String?
        coreDataHelper.performAndWait {
            let entities = coreDataHelper.fetch(
                entity: .attribute,
                where: nil,
                rowLimit: 1).compactMap { $0 as? AttributeEntity }
            if !entities.isEmpty {
                loadedKey = entities[0].userKey
                loadedAttributes = entities[0].attributes
            }
        }
        return (userKey: loadedKey, attributes: loadedAttributes)
    }
}

//
//  AttributesStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class AttributesStorageTests: XCTestCase {
    var attributesStorage: AttributesStorage!
    var persistentStorage: PersistentAttributesStorageStub!

    let testAttributes: [String: Any] = [
        "att1": "se1",
        "att2": true,
        "att3": 1,
    ]

    let otherAttributes: [String: Any] = ["oattr": "ov1"]

    let userKey = "dummyKey"
    let otherKey = "otherKey"

    override func setUp() {
        persistentStorage = PersistentAttributesStorageStub()
        attributesStorage = DefaultAttributesStorage(persistentAttributesStorage: persistentStorage)
    }

    func testNoLoaded() {
        let attributes = attributesStorage.getAll(forKey: userKey)

        XCTAssertEqual(0, attributes.count)
    }

    func testGetAttributesAfterLoad() {
        persistentStorage.attributes = [userKey: testAttributes]
        attributesStorage.loadLocal(forKey: userKey)
        let attributes = attributesStorage.getAll(forKey: userKey)
        let otherAttributes = attributesStorage.getAll(forKey: otherKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes["att3"] as? Int ?? -1)
        XCTAssertEqual(0, otherAttributes.count)
    }

    func testUpdateAttributes() {
        persistentStorage.attributes = [userKey: testAttributes]
        attributesStorage.loadLocal(forKey: userKey)
        let attributes = attributesStorage.getAll(forKey: userKey)
        attributesStorage.set(["att1": "n1", "att2": 1], forKey: userKey)
        let newAttributes = attributesStorage.getAll(forKey: userKey)
        let persistedAttributes = persistentStorage.getAll(forKey: userKey) ?? [:]

        attributesStorage.set(["att1": "senew", "att4": 10], forKey: userKey)

        let updatedAttributes = attributesStorage.getAll(forKey: userKey)
        let updatedPersistedAttributes = persistentStorage.getAll(forKey: userKey) ?? [:]

        attributesStorage.set(value: "selast", name: "att1", forKey: userKey)
        attributesStorage.set(value: 100, name: "att5", forKey: userKey)

        let singleUpdateAttributes = attributesStorage.getAll(forKey: userKey)
        let singlePersistedAttributes = persistentStorage.getAll(forKey: userKey) ?? [:]

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes["att3"] as? Int ?? -1)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual("n1", newAttributes["att1"] as? String ?? "")
        XCTAssertEqual(1, newAttributes["att2"] as? Int ?? -1)

        XCTAssertEqual(3, persistedAttributes.count)
        XCTAssertEqual("n1", persistedAttributes["att1"] as? String ?? "")
        XCTAssertEqual(1, persistedAttributes["att2"] as? Int ?? -1)

        XCTAssertEqual(4, updatedAttributes.count)
        XCTAssertEqual("senew", updatedAttributes["att1"] as? String ?? "")
        XCTAssertEqual(1, updatedAttributes["att2"] as? Int ?? -1)
        XCTAssertEqual(10, updatedAttributes["att4"] as? Int ?? -1)
        XCTAssertEqual(4, updatedPersistedAttributes.count)

        XCTAssertEqual(5, singleUpdateAttributes.count)
        XCTAssertEqual("selast", singleUpdateAttributes["att1"] as? String ?? "")
        XCTAssertEqual(1, singleUpdateAttributes["att2"] as? Int ?? -1)
        XCTAssertEqual(10, singleUpdateAttributes["att4"] as? Int ?? -1)
        XCTAssertEqual(100, singleUpdateAttributes["att5"] as? Int ?? -1)
        XCTAssertEqual(5, singlePersistedAttributes.count)
    }

    func testUpdateEmptyAttributes() {
        persistentStorage.attributes = [userKey: testAttributes]
        attributesStorage.loadLocal(forKey: userKey)
        let attributes = attributesStorage.getAll(forKey: userKey)
        attributesStorage.set([:], forKey: userKey)
        let newAttributes = attributesStorage.getAll(forKey: userKey)
        let persistedAttributes = persistentStorage.getAll(forKey: userKey) ?? [:]

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes["att3"] as? Int ?? -1)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual(3, persistedAttributes.count)
    }

    func testRemove() {
        persistentStorage.attributes = [userKey: testAttributes]
        attributesStorage.loadLocal(forKey: userKey)
        attributesStorage.remove(name: "att1", forKey: userKey)
        let attributes = attributesStorage.getAll(forKey: userKey)
        let persistedAttributes = persistentStorage.getAll(forKey: userKey)

        XCTAssertEqual(2, attributes.count)
        XCTAssertNil(attributes["att1"])
        XCTAssertEqual(true, attributes["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes["att3"] as? Int ?? -1)

        XCTAssertEqual(2, persistedAttributes?.count)
        XCTAssertNil(persistedAttributes?["att1"])
        XCTAssertEqual(true, persistedAttributes?["att2"] as? Bool ?? false)
        XCTAssertEqual(1, persistedAttributes?["att3"] as? Int ?? -1)
    }

    func testClear() {
        persistentStorage.attributes = [userKey: testAttributes]
        attributesStorage.loadLocal(forKey: userKey)
        let attributes = attributesStorage.getAll(forKey: userKey)
        attributesStorage.clear(forKey: userKey)
        let newAttributes = attributesStorage.getAll(forKey: userKey)
        let persistedAttributes = persistentStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as? String ?? "")
        XCTAssertEqual(true, attributes["att2"] as? Bool ?? false)
        XCTAssertEqual(1, attributes["att3"] as? Int ?? -1)

        XCTAssertEqual(0, newAttributes.count)
        XCTAssertNil(persistedAttributes)
    }

    override func tearDown() {}
}

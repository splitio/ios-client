//
//  ByKeyAttributesStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ByKeyAttributesStorageTests: XCTestCase {
    let userKey = "dummyKey"

    var attributesStorage: AttributesStorageStub!
    var byKeyStorage: ByKeyAttributesStorage!

    let testAttributes: [String: Any] = [
        "att1": "se1",
        "att2": true,
        "att3": 1,
    ]

    override func setUp() {
        attributesStorage = AttributesStorageStub()
        byKeyStorage = DefaultByKeyAttributesStorage(
            attributesStorage: attributesStorage,
            userKey: userKey)
    }

    func testNoLoaded() {
        let attributes = byKeyStorage.getAll()

        XCTAssertEqual(0, attributes.count)
    }

    func testGetAttributesAfterLoad() {
        attributesStorage.persistedAttributes = [userKey: testAttributes]
        byKeyStorage.loadLocal()
        let attributes = byKeyStorage.getAll()

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }

    func testUpdateAttributes() {
        attributesStorage.persistedAttributes = [userKey: testAttributes]
        byKeyStorage.loadLocal()
        let attributes = byKeyStorage.getAll()
        byKeyStorage.set(["att1": "n1", "att2": 1])
        let newAttributes = byKeyStorage.getAll()
        let generalAttributes = attributesStorage.getAll(forKey: userKey)

        byKeyStorage.set(["att1": "senew", "att4": 10])

        let updatedAttributes = byKeyStorage.getAll()
        let updatedgeneralAttributes = attributesStorage.getAll(forKey: userKey)

        byKeyStorage.set(value: "selast", name: "att1")
        byKeyStorage.set(value: 100, name: "att5")

        let singleUpdateAttributes = byKeyStorage.getAll()
        let singlegeneralAttributes = attributesStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual("n1", newAttributes["att1"] as! String)
        XCTAssertEqual(1, newAttributes["att2"] as! Int)

        XCTAssertEqual(3, generalAttributes.count)
        XCTAssertEqual("n1", generalAttributes["att1"] as! String)
        XCTAssertEqual(1, generalAttributes["att2"] as! Int)

        XCTAssertEqual(4, updatedAttributes.count)
        XCTAssertEqual("senew", updatedAttributes["att1"] as! String)
        XCTAssertEqual(1, updatedAttributes["att2"] as! Int)
        XCTAssertEqual(10, updatedAttributes["att4"] as! Int)
        XCTAssertEqual(4, updatedgeneralAttributes.count)

        XCTAssertEqual(5, singleUpdateAttributes.count)
        XCTAssertEqual("selast", singleUpdateAttributes["att1"] as! String)
        XCTAssertEqual(1, singleUpdateAttributes["att2"] as! Int)
        XCTAssertEqual(10, singleUpdateAttributes["att4"] as! Int)
        XCTAssertEqual(100, singleUpdateAttributes["att5"] as! Int)
        XCTAssertEqual(5, singlegeneralAttributes.count)
    }

    func testUpdateEmptyAttributes() {
        attributesStorage.persistedAttributes = [userKey: testAttributes]
        byKeyStorage.loadLocal()
        let attributes = byKeyStorage.getAll()
        byKeyStorage.set([:])
        let newAttributes = byKeyStorage.getAll()
        let generalAttributes = attributesStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual(3, generalAttributes.count)
    }

    func testRemove() {
        attributesStorage.persistedAttributes = [userKey: testAttributes]
        byKeyStorage.loadLocal()
        byKeyStorage.remove(name: "att1")
        let attributes = byKeyStorage.getAll()
        let generalAttributes = attributesStorage.getAll(forKey: userKey)

        XCTAssertEqual(2, attributes.count)
        XCTAssertNil(attributes["att1"])
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(2, generalAttributes.count)
        XCTAssertNil(generalAttributes["att1"])
        XCTAssertEqual(true, generalAttributes["att2"] as! Bool)
        XCTAssertEqual(1, generalAttributes["att3"] as! Int)
    }

    func testClear() {
        attributesStorage.persistedAttributes = [userKey: testAttributes]
        byKeyStorage.loadLocal()
        let attributes = byKeyStorage.getAll()
        byKeyStorage.clear()
        let newAttributes = byKeyStorage.getAll()
        let generalAttributes = attributesStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(0, newAttributes.count)
        XCTAssertEqual(0, generalAttributes.count)
    }

    override func tearDown() {}
}

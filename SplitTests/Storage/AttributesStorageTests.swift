//
//  AttributesStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class AttributesStorageTests: XCTestCase {

    var attributesStorage: AttributesStorage!
    var persistentStorage: OneKeyPersistentAttributesStorageStub!

    let testAttributes: [String: Any] = ["att1": "se1",
                                         "att2": true,
                                         "att3": 1]
    
    override func setUp() {
        persistentStorage = OneKeyPersistentAttributesStorageStub()
        attributesStorage = DefaultAttributesStorage(persistentAttributesStorage: persistentStorage)
    }

    func testNoLoaded() {
        let attributes = attributesStorage.getAll()

        XCTAssertEqual(0, attributes.count)
    }

    func testGetAttributesAfterLoad() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        let attributes = attributesStorage.getAll()

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)
    }

    func testUpdateAttributes() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        let attributes = attributesStorage.getAll()
        attributesStorage.set(["att1": "n1", "att2": 1])
        let newAttributes = attributesStorage.getAll()
        let persistedAttributes = persistentStorage.getAll()!

        attributesStorage.set(["att1": "senew", "att4": 10])

        let updatedAttributes = attributesStorage.getAll()
        let updatedPersistedAttributes = persistentStorage.getAll()!

        attributesStorage.set(value: "selast", name: "att1")
        attributesStorage.set(value: 100, name: "att5")

        let singleUpdateAttributes = attributesStorage.getAll()
        let singlePersistedAttributes = persistentStorage.getAll()!

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual("n1", newAttributes["att1"] as! String)
        XCTAssertEqual(1, newAttributes["att2"] as! Int)

        XCTAssertEqual(3, persistedAttributes.count)
        XCTAssertEqual("n1", persistedAttributes["att1"] as! String)
        XCTAssertEqual(1, persistedAttributes["att2"] as! Int)

        XCTAssertEqual(4, updatedAttributes.count)
        XCTAssertEqual("senew", updatedAttributes["att1"] as! String)
        XCTAssertEqual(1, updatedAttributes["att2"] as! Int)
        XCTAssertEqual(10, updatedAttributes["att4"] as! Int)
        XCTAssertEqual(4, updatedPersistedAttributes.count)

        XCTAssertEqual(5, singleUpdateAttributes.count)
        XCTAssertEqual("selast", singleUpdateAttributes["att1"] as! String)
        XCTAssertEqual(1, singleUpdateAttributes["att2"] as! Int)
        XCTAssertEqual(10, singleUpdateAttributes["att4"] as! Int)
        XCTAssertEqual(100, singleUpdateAttributes["att5"] as! Int)
        XCTAssertEqual(5, singlePersistedAttributes.count)
    }

    func testUpdateEmptyAttributes() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        let attributes = attributesStorage.getAll()
        attributesStorage.set([:])
        let newAttributes = attributesStorage.getAll()
        let persistedAttributes = persistentStorage.getAll()!



        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(3, newAttributes.count)
        XCTAssertEqual(3, persistedAttributes.count)
    }

    func testRemove() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        attributesStorage.remove(name: "att1")
        let attributes = attributesStorage.getAll()
        let persistedAttributes = persistentStorage.getAll()!

        XCTAssertEqual(2, attributes.count)
        XCTAssertNil(attributes["att1"])
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(2, persistedAttributes.count)
        XCTAssertNil(persistedAttributes["att1"])
        XCTAssertEqual(true, persistedAttributes["att2"] as! Bool)
        XCTAssertEqual(1, persistedAttributes["att3"] as! Int)
    }

    func testClear() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        let attributes = attributesStorage.getAll()
        attributesStorage.clear()
        let newAttributes = attributesStorage.getAll()
        let persistedAttributes = persistentStorage.getAll()

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(0, newAttributes.count)
        XCTAssertNil(persistedAttributes)
    }

    override func tearDown() {

    }
}

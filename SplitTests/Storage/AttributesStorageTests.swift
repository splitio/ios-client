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
    var persistentStorage: PersistentAttributesStorageStub!

    let testAttributes: [String: Any] = ["att1": "se1",
                                         "att2": true,
                                         "att3": 1]
    
    override func setUp() {
        persistentStorage = PersistentAttributesStorageStub()
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

        XCTAssertEqual(3, attributes.count)
        XCTAssertEqual("se1", attributes["att1"] as! String)
        XCTAssertEqual(true, attributes["att2"] as! Bool)
        XCTAssertEqual(1, attributes["att3"] as! Int)

        XCTAssertEqual(2, persistedAttributes.count)
        XCTAssertEqual("n1", persistedAttributes["att1"] as! String)
        XCTAssertEqual(1, persistedAttributes["att2"] as! Int)

        XCTAssertEqual(2, newAttributes.count)
        XCTAssertEqual("n1", newAttributes["att1"] as! String)
        XCTAssertEqual(1, newAttributes["att2"] as! Int)
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

        XCTAssertEqual(0, newAttributes.count)
        XCTAssertEqual(0, persistedAttributes.count)
    }

    func testRemove() {
        persistentStorage.attributes = testAttributes
        attributesStorage.loadLocal()
        attributesStorage.remove(key: "att1")
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

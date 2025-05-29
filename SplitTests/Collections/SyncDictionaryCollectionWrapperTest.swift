//
//  SyncDictionaryCollectionWrapperTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SyncDictionaryCollectionWrapperTest: XCTestCase {
    var dic: ConcurrentDictionaryList<String, String>!
    override func setUp() {
        dic = ConcurrentDictionaryList()
        dic.appendValue("k1value1", toKey: "key1")
        dic.appendValue("k1value2", toKey: "key1")
        dic.appendValue("k1value3", toKey: "key1")

        dic.appendValue("k2value1", toKey: "key2")
        dic.appendValue("k2value2", toKey: "key2")

        dic.appendValue("k3value1", toKey: "key3")
        dic.appendValue("k3value2", toKey: "key3")
        dic.appendValue("k3value3", toKey: "key3")
        dic.appendValue("k3value4", toKey: "key3")
    }

    override func tearDown() {}

    func testInitialAppend() {
        let v1 = dic.value(forKey: "key1")
        let v2 = dic.value(forKey: "key2")
        let v3 = dic.value(forKey: "key3")

        XCTAssertEqual(9, dic.count)
        XCTAssertEqual(3, v1?.count)
        XCTAssertEqual(2, v2?.count)
        XCTAssertEqual(4, v3?.count)

        XCTAssertTrue(indexForValue(value: "k1value1", array: v1) != -1)
        XCTAssertTrue(indexForValue(value: "k2value1", array: v2) != -1)
        XCTAssertTrue(indexForValue(value: "k3value1", array: v3) != -1)
    }

    func testRemoveValue() {
        dic.removeValues(forKeys: ["key1", "key2"])
        XCTAssertEqual(4, dic.count)
        XCTAssertNil(dic.value(forKey: "key1"))
        XCTAssertNil(dic.value(forKey: "key2"))
    }

    func testAllValues() {
        dic.removeAll()
        XCTAssertEqual(0, dic.count)
    }

    private func indexForValue(value: String, array: [String]?) -> Int {
        guard let array = array else {
            return -1
        }
        for (index, element) in array.enumerated() {
            if element == value {
                return index
            }
        }
        return -1
    }
}

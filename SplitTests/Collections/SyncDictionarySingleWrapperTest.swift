//
//  SyncDictionarySingleWrapperTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SyncDictionarySingleWrapperTest: XCTestCase {
    var dic: ConcurrentDictionary<String, String>!
    override func setUp() {
        dic = ConcurrentDictionary()
        dic.setValue("k1value1", forKey: "key1")
        dic.setValue("k1value2", forKey: "key1")
        dic.setValue("k1value", forKey: "key1")

        dic.setValue("k2value1", forKey: "key2")
        dic.setValue("k2value", forKey: "key2")

        dic.setValue("k3value", forKey: "key3")
        dic.setValue("k4value", forKey: "key4")
        dic.setValue("k5value", forKey: "key5")
        dic.setValue("k6value", forKey: "key6")
    }

    override func tearDown() {}

    func testInitialSetup() {
        let v1 = dic.value(forKey: "key1")
        let v2 = dic.value(forKey: "key2")
        let v5 = dic.value(forKey: "key5")

        XCTAssertEqual(6, dic.count)

        XCTAssertEqual("k1value", v1)
        XCTAssertEqual("k2value", v2)
        XCTAssertEqual("k5value", v5)
    }

    func testRemoveValue() {
        dic.removeValue(forKey: "key1")
        dic.removeValue(forKey: "key4")
        dic.removeValue(forKey: "key6")
        XCTAssertEqual(3, dic.count)
        XCTAssertNil(dic.value(forKey: "key1"))
        XCTAssertNil(dic.value(forKey: "key4"))
        XCTAssertNil(dic.value(forKey: "key6"))
    }

    func testAllValues() {
        let values = dic.all

        for i in 1 ... 6 {
            let v = values["key\(i)"]
            XCTAssertEqual("k\(i)value", v)
        }
    }

    func testRemoveAllValues() {
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

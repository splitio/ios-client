//
//  ConcurrentSetTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ConcurrentSetTests: XCTestCase {
    var concurrentSet: ConcurrentSet<String>!

    override func setUp() {
        concurrentSet = ConcurrentSet()
    }

    func testInsert() {
        for i in 0 ..< 5 {
            concurrentSet.insert("pepe_\(i)")
        }

        let s = concurrentSet.all

        XCTAssertEqual(5, s.count)
    }

    func testDeleteAll() {
        for i in 0 ..< 5 {
            concurrentSet.insert("pepe_\(i)")
        }
        concurrentSet.removeAll()

        let s = concurrentSet.all

        XCTAssertEqual(0, s.count)
    }

    func testTakeAll() {
        for i in 0 ..< 5 {
            concurrentSet.insert("pepe_\(i)")
        }

        let s = concurrentSet.takeAll()
        let s1 = concurrentSet.all

        XCTAssertEqual(5, s.count)
        XCTAssertEqual(0, s1.count)
    }

    func testSet() {
        for i in 0 ..< 5 {
            concurrentSet.insert("pepe_\(i)")
        }

        concurrentSet.set(["s1", "s2"])

        let s = concurrentSet.all

        XCTAssertEqual(2, s.count)
    }

    override func tearDown() {}
}

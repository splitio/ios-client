//
//  ConcurrentSetTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ConcurrentSetTests: XCTestCase {

    var concurrentSet: ConcurrentSet<String>!

    override func setUp() {
        concurrentSet = ConcurrentSet()
    }

    func testInsert() {
        for i in 0..<5 {
            concurrentSet.insert("pepe_\(i)")
        }

        let s = concurrentSet.all

        XCTAssertEqual(5, s.count)
    }

    override func tearDown() {

    }
}

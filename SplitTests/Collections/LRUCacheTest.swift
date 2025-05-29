//
//  LRUCacheTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class LRUCacheTest: XCTestCase {
    var cache: LRUCache<Int, Int>!

    override func setUp() {
        cache = LRUCache(capacity: 10)
    }

    func testAddGet() {
        for i in 0 ..< 5 {
            cache.set(i, for: i)
        }

        for i in 0 ..< 5 {
            XCTAssertNotNil(cache.element(for: i))
        }
        XCTAssertNil(cache.element(for: 20))
    }

    func testEviction() {
        for i in 0 ..< 10 {
            cache.set(i, for: i)
        }

        cache.set(10, for: 10)

        let ele0Evicted = cache.element(for: 0)
        // using 1 to avoid eviction and make 2 to be evicted
        let ele1 = cache.element(for: 1)
        cache.set(20, for: 20)

        // Check ele1 non evicted
        let ele1Check = cache.element(for: 1)

        // Check ele2 evicted
        let ele2Check = cache.element(for: 2)

        // Now same check for 3
        let ele3 = cache.element(for: 3)
        cache.set(30, for: 30)

        // Check ele1 non evicted
        let ele3Check = cache.element(for: 3)

        XCTAssertNil(ele0Evicted)
        XCTAssertNotNil(ele1)
        XCTAssertNotNil(ele1Check)
        XCTAssertNil(ele2Check)
        XCTAssertNotNil(ele3)
        XCTAssertNotNil(ele3Check)
    }

    func testInsertPerformance() {
        let cache = LRUCache<Int, Int>(capacity: 500)
        measure {
            for i in 0 ..< 1000 {
                cache.set(i, for: i)
            }
        }
    }

    func testGetAllPerformance() {
        let cache = LRUCache<Int, Int>(capacity: 500)
        for i in 0 ..< 500 {
            cache.set(i, for: i)
        }

        measure {
            for i in 0 ..< 500 {
                let _ = cache.element(for: i)
            }
        }

        cache.clear()
    }

    override func tearDown() {}
}

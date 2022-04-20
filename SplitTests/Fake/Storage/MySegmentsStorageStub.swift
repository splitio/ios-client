//
//  MySegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class MySegmentsStorageStub: MySegmentsStorage {
    var segments: [String: Set<String>] = [String: Set<String>]()
    var persistedSegments = [String: Set<String>]()
    var loadLocalCalled = false
    var clearCalled = false
    var updateExpectation: XCTestExpectation?
    var clearExpectation: XCTestExpectation?
    var getCountCalledCount = 0

    func loadLocal(forKey key: String) {
        segments = persistedSegments
        loadLocalCalled = true
    }
    
    func getAll(forKey key: String) -> Set<String> {
        return segments[key] ?? Set()
    }

    func set(_ segments: [String], forKey key: String) {
        self.segments[key] = Set(segments)
        if let exp = updateExpectation {
            exp.fulfill()
        }
    }

    func clear(forKey key: String) {
        segments[key] = Set()
        if let exp = clearExpectation {
            exp.fulfill()
        }
    }

    func destroy() {
        segments.removeAll()
    }

    func getCount(forKey key: String) -> Int {
        return segments[key]?.count ?? 0
    }

    func getCount() -> Int {
        var count = 0
        for (_, value) in segments {
            count += value.count
        }
        return count
    }


}

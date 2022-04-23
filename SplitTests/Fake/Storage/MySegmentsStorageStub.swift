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

    var updateExpectation = [String: XCTestExpectation]()
    var clearExpectation = [String: XCTestExpectation]()
    var getCountByKeyCalledCount = 0
    var getCountCalledCount = 0

    var keys: Set<String> {
        return Set(segments.keys.map { $0 })
    }

    var loadLocalForKeyCalled = [String: Bool]()
    func loadLocal(forKey key: String) {
        loadLocalForKeyCalled[key] = true
        segments = persistedSegments
    }
    
    func getAll(forKey key: String) -> Set<String> {
        return segments[key] ?? Set()
    }

    func set(_ segments: [String], forKey key: String) {
        self.segments[key] = Set(segments)
        if let exp = updateExpectation[key] {
            exp.fulfill()
        }
    }

    var clearForKeyCalled = [String: Bool]()
    func clear(forKey key: String) {
        clearForKeyCalled[key] = true
        segments[key] = Set()
        if let exp = clearExpectation[key] {
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
        getCountCalledCount+=1
        var count = 0
        for (_, value) in segments {
            count += value.count
        }
        return count
    }


}

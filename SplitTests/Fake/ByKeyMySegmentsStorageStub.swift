//
//  ByKeyMySegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class ByKeyMySegmentsStorageStub: ByKeyMySegmentsStorage {

    var segments: Set = ["s1", "s2", "s3"]
    var updatedSegments: [String]?
    var loadLocalCalled = false
    var clearCalled = false
    var isUsingSegmentsCalled = false
    var updateExpectation: XCTestExpectation?
    var clearExpectation: XCTestExpectation?
    var getCountCalledCount = 0

    var changeNumber: Int64 = -1

    func loadLocal() {
        loadLocalCalled = true
    }

    func getAll() -> Set<String> {
        return segments
    }

    func set(_ change: SegmentChange) {
        updatedSegments = change.segments.map { $0.name }
        self.segments = Set(segments)
        if let exp = updateExpectation {
            exp.fulfill()
        }
    }

    func clear() {
        if let exp = clearExpectation {
            exp.fulfill()
        }
        clearCalled = true
    }

    func destroy() {
    }

    func getCount() -> Int {
        getCountCalledCount+=1
        return segments.count
    }
    
    func isUsingSegments() -> Bool {
        segments.count != 0
    }
}

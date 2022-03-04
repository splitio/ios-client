//
//  OneKeyMySegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class OneKeyMySegmentsStorageStub: OneKeyMySegmentsStorage {

    var segments: Set = ["s1", "s2", "s3"]
    var updatedSegments: [String]?
    var loadLocalCalled = false
    var clearCalled = false
    var updateExpectation: XCTestExpectation?
    var clearExpectation: XCTestExpectation?
    var getCountCalledCount = 0

    func loadLocal() {
        loadLocalCalled = true
    }

    func getAll() -> Set<String> {
        return segments
    }

    func set(_ segments: [String]) {
        updatedSegments = segments
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
}

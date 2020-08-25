//
//  MySegmentsCacheStubs.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 09/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class MySegmentsCacheStub: MySegmentsCacheProtocol {
    
    let segments: Set = ["s1", "s2", "s3"]
    var updatedSegments: [String]?
    var clearCalled = false
    var updateExpectation: XCTestExpectation?
    var clearExpectation: XCTestExpectation?

    func setSegments(_ segments: [String]) {
        updatedSegments = segments
        if let exp = updateExpectation {
            exp.fulfill()
        }
    }
    
    func removeSegments() {
    }
    
    func getSegments() -> [String] {
        return Array(segments)
    }
    
    func isInSegments(name: String) -> Bool {
        return true
    }
    
    func clear() {
        clearCalled = true
        if let exp = clearExpectation {
            exp.fulfill()
        }
    }
    
    
}

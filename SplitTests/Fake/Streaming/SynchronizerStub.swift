//
//  SynchronizerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SynchronizerStub: Synchronizer {
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeMySegmentsCalled = false

    var syncSplitsExp: XCTestExpectation?
    var syncSplitsChangeNumberExp: XCTestExpectation?
    var syncMySegmentsExp: XCTestExpectation?

    func synchronizeSplits() {
        synchronizeSplitsCalled = true
        if let exp = syncSplitsExp {
            exp.fulfill()
        }
    }

    func synchronizeSplits(changeNumber: Int64) {
        synchronizeSplitsChangeNumberCalled = true
        if let exp = syncSplitsChangeNumberExp {
            exp.fulfill()
        }
    }

    func synchronizeMySegments() {
        synchronizeMySegmentsCalled = true
        if let exp = syncMySegmentsExp {
            exp.fulfill()
        }
    }
}

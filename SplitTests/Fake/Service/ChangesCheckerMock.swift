//
//  ChangesCheckerMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split

struct MySegmentsChangesCheckerMock: MySegmentsChangesChecker {
    var haveChanged = false
    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool {
        return haveChanged
    }

    func mySegmentsHaveChanged(oldSegments old: [String], newSegments new: [String]) -> Bool {
        return haveChanged
    }
}

struct SplitsChangesCheckerMock: SplitsChangesChecker {
    var haveChanged = false
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool {
        return haveChanged
    }
}

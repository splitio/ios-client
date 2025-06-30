//
//  ChangesCheckerMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split

class MySegmentsChangesCheckerMock: MySegmentsChangesChecker {

    var haveChanged = false
    var diffSegments: [String] = []

    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool {
        haveChanged
    }

    func mySegmentsHaveChanged(oldSegments old: [Segment], newSegments new: [Segment]) -> Bool {
        haveChanged
    }

    func mySegmentsHaveChanged(oldSegments old: [String], newSegments new: [String]) -> Bool {
        haveChanged
    }
    
    func getSegmentsDiff(oldSegments: [Segment], newSegments: [Segment]) -> [String] {
        diffSegments
    }
}

struct SplitsChangesCheckerMock: SplitsChangesChecker {
    var haveChanged = false
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool {
        haveChanged
    }
}

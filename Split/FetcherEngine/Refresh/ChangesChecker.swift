//
//  ChangesChecker.swift
//  Split
//
//  Created by Javier Avrudsky on 23/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol SplitsChangesChecker {
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool
}

protocol MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool
    func mySegmentsHaveChanged(oldSegments: [String], newSegments: [String]) -> Bool
}

struct DefaultSplitsChangesChecker: SplitsChangesChecker {
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool {
        return oldChangeNumber < newChangeNumber
    }
}

struct DefaultMySegmentsChangesChecker: MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool {
        return mySegmentsHaveChanged(oldSegments: old.segments, newSegments: new.segments)
    }

    func mySegmentsHaveChanged(oldSegments: [String], newSegments: [String]) -> Bool {
        return !(oldSegments.count == newSegments.count &&
                 oldSegments.sorted() == newSegments.sorted())
    }
}

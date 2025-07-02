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

struct DefaultSplitsChangesChecker: SplitsChangesChecker {
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool {
        return oldChangeNumber < newChangeNumber
    }
}

protocol MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool
    func mySegmentsHaveChanged(oldSegments: [Segment], newSegments: [Segment]) -> Bool
    func mySegmentsHaveChanged(oldSegments: [String], newSegments: [String]) -> Bool
    func getSegmentsDiff(oldSegments: [Segment], newSegments: [Segment]) -> [String]
}

struct DefaultMySegmentsChangesChecker: MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: SegmentChange, new: SegmentChange) -> Bool {
        if old.changeNumber ?? -1 > new.changeNumber ?? -1 {
            return false
        }
        return mySegmentsHaveChanged(oldSegments: old.segments, newSegments: new.segments)
    }

    func mySegmentsHaveChanged(oldSegments: [Segment], newSegments: [Segment]) -> Bool {
        let old = oldSegments.map { $0.name }
        let new = newSegments.map { $0.name }
        return mySegmentsHaveChanged(oldSegments: old, newSegments: new)
    }

    func mySegmentsHaveChanged(oldSegments: [String], newSegments: [String]) -> Bool {
        return !(oldSegments.count == newSegments.count &&
                 oldSegments.sorted() == newSegments.sorted())
    }
  
    func getSegmentsDiff(oldSegments: [Segment], newSegments: [Segment]) -> [String] {
        oldSegments.filter { !Set(newSegments.map { $0.name }).contains($0.name) }.map { $0.name }
    }
}

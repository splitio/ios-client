//
//  RuleBasedSegmentsStorageStub.swift
//  SplitTests
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class RuleBasedSegmentsStorageStub: RuleBasedSegmentsStorage {

    var segments = [String: RuleBasedSegment]()
    var changeNumber: Int64 = -1
    
    var segmentsInUse: Int64 = 0

    var getCalled = false
    var containsCalled = false
    var updateCalled = false
    var clearCalled = false
    var loadLocalCalled = false

    var lastRequestedSegmentName: String?
    var lastRequestedMatchingKey: String?
    var lastRequestedSegmentNames: Set<String>?
    var lastAddedSegments: Set<RuleBasedSegment>?
    var lastRemovedSegments: Set<RuleBasedSegment>?
    var lastChangeNumber: Int64?

    func get(segmentName: String) -> RuleBasedSegment? {
        getCalled = true
        lastRequestedSegmentName = segmentName
        return segments[segmentName.lowercased()]
    }

    func contains(segmentNames: Set<String>) -> Bool {
        containsCalled = true
        lastRequestedSegmentNames = segmentNames
        let lowercasedNames = segmentNames.map { $0.lowercased() }
        let segmentKeys = Set(segments.keys)
        return !lowercasedNames.filter { segmentKeys.contains($0) }.isEmpty
    }

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) -> Bool {
        updateCalled = true
        lastAddedSegments = toAdd
        lastRemovedSegments = toRemove
        lastChangeNumber = changeNumber

        // Process segments to add
        for segment in toAdd {
            if let segmentName = segment.name?.lowercased() {
                segments[segmentName] = segment
            }
        }

        // Process segments to remove
        for segment in toRemove {
            if let segmentName = segment.name?.lowercased() {
                segments.removeValue(forKey: segmentName)
            }
        }

        self.changeNumber = changeNumber
        return true
    }
    
    func clear() {
        clearCalled = true
        segments.removeAll()
        changeNumber = -1
    }

    func loadLocal() {
        loadLocalCalled = true
    }
}

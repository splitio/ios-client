//
//  PersistentRuleBasedSegmentsStorageStub.swift
//  SplitTests
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentRuleBasedSegmentsStorageStub: PersistentRuleBasedSegmentsStorage {

    var changeNumber: Int64 = -1

    var snapshot: RuleBasedSegmentsSnapshot = RuleBasedSegmentsSnapshot(
        changeNumber: -1,
        segments: [RuleBasedSegment]()
    )

    var updateCalled = false
    var clearCalled = false
    
    var lastAddedSegments: Set<RuleBasedSegment>?
    var lastRemovedSegments: Set<RuleBasedSegment>?
    var lastChangeNumber: Int64?

    var segments = [String: RuleBasedSegment]()

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) {
        updateCalled = true
        lastAddedSegments = toAdd
        lastRemovedSegments = toRemove
        lastChangeNumber = changeNumber

        // Process segments to add
        for segment in toAdd {
            if let segmentName = segment.name ?? "" {
                segments[segmentName] = segment
            }
        }

        // Process segments to remove
        for segment in toRemove {
            if let segmentName = segment.name ?? "" {
                segments.removeValue(forKey: segmentName)
            }
        }

        self.changeNumber = changeNumber
        snapshot = RuleBasedSegmentsSnapshot(
            changeNumber: changeNumber,
            segments: segments.values.compactMap { $0 }
        )
    }

    func getSegmentsSnapshot() -> RuleBasedSegmentsSnapshot {
        return snapshot
    }

    func getChangeNumber() -> Int64 {
        return changeNumber
    }

    func clear() {
        clearCalled = true
        segments.removeAll()
        changeNumber = -1
        snapshot = RuleBasedSegmentsSnapshot(
            changeNumber: -1,
            segments: []
        )
    }
}

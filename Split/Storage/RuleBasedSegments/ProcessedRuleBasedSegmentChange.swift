//
//  ProcessedRuleBasedSegmentChange.swift
//  Split
//
//  Created on 19/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

struct ProcessedRuleBasedSegmentChange {
    let activeSegments: [RuleBasedSegment]
    let archivedSegments: [RuleBasedSegment]
    let changeNumber: Int64
    let updateTimestamp: Int64

    var toAdd: Set<RuleBasedSegment> {
        return Set(activeSegments)
    }

    var toRemove: Set<RuleBasedSegment> {
        return Set(archivedSegments)
    }
}

protocol RuleBasedSegmentChangeProcessor {
    func process(_ segmentChange: RuleBasedSegmentChange) -> ProcessedRuleBasedSegmentChange
}

class DefaultRuleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor {

    func process(_ segmentChange: RuleBasedSegmentChange) -> ProcessedRuleBasedSegmentChange {
        let active = segmentChange.segments.filter { $0.status == .active }
        let archived = segmentChange.segments.filter { $0.status == .archived }

        return ProcessedRuleBasedSegmentChange(
            activeSegments: active,
            archivedSegments: archived,
            changeNumber: segmentChange.till,
            updateTimestamp: Date.nowMillis()
        )
    }
}

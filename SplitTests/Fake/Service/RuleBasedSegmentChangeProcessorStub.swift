//
//  RuleBasedSegmentChangeProcessorStub.swift
//  Split
//
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class RuleBasedSegmentChangeProcessorStub: RuleBasedSegmentChangeProcessor {
    var processedRuleBasedSegmentsChange: ProcessedRuleBasedSegmentChange = ProcessedRuleBasedSegmentChange(activeSegments: [], archivedSegments: [], changeNumber: -1, updateTimestamp: -1)

    var segmentChange: RuleBasedSegmentChange?
    func process(_ segmentChange: RuleBasedSegmentChange) -> ProcessedRuleBasedSegmentChange {
        self.segmentChange = segmentChange
        return processedRuleBasedSegmentsChange
    }
}

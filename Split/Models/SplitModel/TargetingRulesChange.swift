//
//  TargetingRulesChange.swift
//  Split
//
//  Created on 19/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

@objc class TargetingRulesChange: NSObject, Codable {
    var featureFlags: SplitChange
    var ruleBasedSegments: RuleBasedSegmentChange

    enum CodingKeys: String, CodingKey {
        case featureFlags = "ff"
        case ruleBasedSegments = "rbs"
    }

    init(featureFlags: SplitChange, ruleBasedSegments: RuleBasedSegmentChange) {
        self.featureFlags = featureFlags
        self.ruleBasedSegments = ruleBasedSegments
        super.init()
    }

    convenience init(featureFlags: SplitChange) {
        self.init(featureFlags: featureFlags, ruleBasedSegments: RuleBasedSegmentChange.empty())
    }
}

extension TargetingRulesChange {
    override public var description: String {
        let ff = String(describing: featureFlags)
        let rbs = String(describing: ruleBasedSegments)
        return "{\nfeatureFlags: \(ff),\nruleBasedSegments: \(rbs)\n}"
    }
}

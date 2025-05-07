//
//  RuleBasedSegmentChange.swift
//  Split
//
//  Created on 19/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

@objc class RuleBasedSegmentChange: NSObject, Codable {
    var segments: [RuleBasedSegment]
    var since: Int64
    var till: Int64

    enum CodingKeys: String, CodingKey {
        case segments = "d"
        case since = "s"
        case till = "t"
    }

    init(segments: [RuleBasedSegment], since: Int64, till: Int64) {
        self.segments = segments
        self.since = since
        self.till = till
    }

    static func empty() -> RuleBasedSegmentChange {
        return RuleBasedSegmentChange(segments: [], since: -1, till: -1)
    }
}

extension RuleBasedSegmentChange {
    override public var description: String {
        let since = String(describing: self.since)
        let till = String(describing: self.till)
        let segments = String(describing: self.segments)
        return "{\nsince: \(since),\ntill: \(String(describing: till)),\nsegments: \(String(describing: segments))\n}"
    }
}

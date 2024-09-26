//
//  SegmentsChange.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct SegmentChange: Codable {
    var segments: [Segment]
    var changeNumber: Int64?
    var unwrappedChangeNumber: Int64 {
        return changeNumber ?? ServiceConstants.defaultSegmentsChangeNumber
    }

    init(segments: [String], changeNumber: Int64? = nil) {
        self.segments = segments.compactMap { Segment(name: $0) }
        self.changeNumber = changeNumber
    }

    enum CodingKeys: String, CodingKey {
        case changeNumber = "cn"
        case segments = "k"
    }

    static func empty() -> SegmentChange {
        return SegmentChange(segments: [])
    }
}

//
//  SegmentsChange.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
struct MySegmentsChange: Codable {
    var changeNumber: Int64
    var segments: [String]
}

struct AllSegmentsChange: Codable {
    var mySegmentsChange: MySegmentsChange
    var myLargeSegmentsChange: MySegmentsChange

    func mySegmentChange() -> SegmentChange {
        return SegmentChange(segments: mySegmentsChange.segments,
                             changeNumber: -1)
    }

    func myLargeSegmentChange() -> SegmentChange {
        return SegmentChange(segments: myLargeSegmentsChange.segments,
                             changeNumber: myLargeSegmentsChange.changeNumber)
    }
}

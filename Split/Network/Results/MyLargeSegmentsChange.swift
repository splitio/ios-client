//
//  MyLargeSegmentsChange.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct MyLargeSegmentChange: Codable {
    var segments: [Segment]
    var changeNumber: Int64

    init(segments: [Segment], changeNumber: Int64) {
        self.segments = segments
        self.changeNumber = changeNumber
    }
}

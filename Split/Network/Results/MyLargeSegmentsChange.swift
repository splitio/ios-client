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
    var till: Int64

    init(segments: [Segment], till: Int64) {
        self.segments = segments
        self.till = till
    }
}

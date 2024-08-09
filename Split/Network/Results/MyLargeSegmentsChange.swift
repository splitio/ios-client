//
//  MyLargeSegmentsChange.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct MyLargeSegmentsChange: Codable {
    var myLargeSegments: [String]
    var changeNumber: Int64

    func asSegmentChange() -> SegmentChange {
        return SegmentChange(segments: myLargeSegments, changeNumber: changeNumber)
    }
}

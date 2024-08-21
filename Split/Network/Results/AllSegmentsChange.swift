//
//  SegmentsChange.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct AllSegmentsChange: Codable {
    var mySegmentsChange: SegmentChange
    var myLargeSegmentsChange: SegmentChange

    enum CodingKeys: String, CodingKey {
        case mySegmentsChange = "ms"
        case myLargeSegmentsChange = "ls"
    }
    //    {
//      ms: {
//        cn?: integer, // ATM not available for mySegments, but it might be available in the future
//        k: [{ n: 'segment_name_1' }, { n: 'segment_name_2' }, ...] // make sure we can expand the object for each segment safely
//      },
//      ls: {
//        cn?: integer, // Available for myLargeSegments
//        k: [{ n: 'large_segment_name_1' }, { n: 'large_segment_name_2' }, ...] // make sure we can expand the object for each segment safely
//      },
//    }
}

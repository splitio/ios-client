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
    var changeNumbers: SegmentsChangeNumber {
        return SegmentsChangeNumber(
            msChangeNumber: mySegmentsChange.unwrappedChangeNumber,
            mlsChangeNumber: myLargeSegmentsChange.unwrappedChangeNumber)
    }

    enum CodingKeys: String, CodingKey {
        case mySegmentsChange = "ms"
        case myLargeSegmentsChange = "ls"
    }
}

struct SegmentsChangeNumber {
    // My Segments
    let msChangeNumber: Int64
    // My Large Segments
    let mlsChangeNumber: Int64

    func max() -> Int64 {
        return Int64([msChangeNumber, mlsChangeNumber].max() ?? -1)
    }

    func asString() -> String {
        return "\(msChangeNumber)_\(mlsChangeNumber)"
    }
}

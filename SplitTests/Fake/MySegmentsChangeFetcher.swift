//
//  MySegmentsChangeFetcher.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsChangeFetcherStub: MySegmentsChangeFetcher {
    var fetchMySegmentsCount = 0
    private var segmentsIndex = -1
    var allSegments: [[String]?]?
    func fetch(user: String, policy: FecthingPolicy) throws -> [String]? {
        fetchMySegmentsCount+=1
        var segments: [String]? = nil
        if let allSegments = self.allSegments {
            if  segmentsIndex < allSegments.count - 1 {
                segmentsIndex+=1
            }
            segments = allSegments[segmentsIndex]
        }
        return segments
    }
}

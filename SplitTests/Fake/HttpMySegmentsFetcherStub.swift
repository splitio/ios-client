//
//  HttpMySegmentsFetcherStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpMySegmentsFetcherStub: HttpMySegmentsFetcher {
    var fetchMySegmentsCount = 0
    private var segmentsIndex = -1
    var segments: [AllSegmentsChange?]?
    var httpError: HttpError?
    var headerList = [[String: String]]()

    func execute(userKey: String, headers: [String: String]?) throws -> AllSegmentsChange? {

        if let error = httpError {
            throw error
        }
        fetchMySegmentsCount+=1
        if let headers = headers {
            self.headerList.append(headers)
        }
        var change: AllSegmentsChange? = nil
        if let segments = self.segments {
            if  segmentsIndex < segments.count - 1 {
                segmentsIndex+=1
            }
            change = segments[segmentsIndex]
        }
       return change
    }

    func emptyChange() -> SegmentChange {
        return SegmentChange(segments: [])
    }
}

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
    var allSegments: [[String]?]?
    var httpError: HttpError?
    var headerList = [[String: String]]()

    func execute(userKey: String, headers: [String: String]?) throws -> [String]? {

        if let error = httpError {
            throw error
        }
        fetchMySegmentsCount+=1
        if let headers = headers {
            self.headerList.append(headers)
        }
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

//
//  HttpMySegmentsFetcherStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpMySegmentsFetcherStub: HttpMySegmentsFetcher {
    var fetchMySegmentsCount = 0
    private var segmentsIndex = AtomicInt(-1)
    var segments: [AllSegmentsChange?]?
    var httpError: HttpError?
    var headerList = [[String: String]]()
    var countExp: XCTestExpectation?
    var lastUserKey: String?
    var lastTill: Int64?
    var limitCountExp: Int = 0

    func execute(
        userKey: String,
        till: Int64?,
        headers: [String: String]?) throws -> AllSegmentsChange? {
        print("Executing segments fetch stub")
        lastUserKey = userKey
        lastTill = till

        if let error = httpError {
            throw error
        }
        fetchMySegmentsCount += 1
        if let headers = headers {
            headerList.append(headers)
        }
        var change: AllSegmentsChange? = nil
        if let segments = segments {
            segmentsIndex.mutate {
                if $0 < segments.count - 1 {
                    $0 += 1
                }
            }
            change = segments[segmentsIndex.value]
        }
        if fetchMySegmentsCount >= limitCountExp {
            countExp?.fulfill()
        }
        return change
    }

    func emptyChange() -> SegmentChange {
        return SegmentChange(segments: [])
    }
}

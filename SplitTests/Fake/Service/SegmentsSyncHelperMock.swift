//
//  SegmentsSyncHelperMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/09/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SegmentsSyncHelperMock: SegmentsSyncHelper {
    var results = [SegmentsSyncResult]()
    var syncCallCount = 0
    var syncCallIndex = 0
    var lastMsTillParam: Int64?
    var lastMlsTillParam: Int64?
    var lastHeadersParam: HttpHeaders?
    var exp: XCTestExpectation?
    var expSyncLimit: Int = 0

    func sync(msTill: Int64, mlsTill: Int64, headers: HttpHeaders?) throws -> SegmentsSyncResult {
        lastMsTillParam = msTill
        lastMlsTillParam = mlsTill
        lastHeadersParam = headers
        if syncCallIndex < results.count - 1 {
            syncCallIndex += 1
        }
        syncCallCount += 1
        if syncCallCount >= expSyncLimit {
            exp?.fulfill()
        }
        return results[syncCallIndex]
    }
}

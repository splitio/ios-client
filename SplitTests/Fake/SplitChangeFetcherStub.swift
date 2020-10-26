//
//  SplitChangeFetcherStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/05/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitChangeFetcherStub: SplitChangeFetcher {
    var fetchExpectation: XCTestExpectation?
    var since: Int64 = -1
    var fetchCallCount = 0

    var changeResponseIndex = -1
    var changes: [SplitChange?]?
    var clearCacheParams = [Bool]()

    func fetch(since: Int64, policy: FecthingPolicy, clearCache: Bool) throws -> SplitChange? {
        fetchCallCount+=1
        self.since = since
        var change: SplitChange?
        self.clearCacheParams.append(clearCache)
        if let changes = self.changes {
            if changeResponseIndex + 1 < changes.count {
                changeResponseIndex+=1
            }
            change = changes[changeResponseIndex]
        } else {
            change = SplitChange()
            change?.splits = [Split]()
            change?.since = since + 100
            change?.till = since + 200
        }
        if let exp = fetchExpectation {
            exp.fulfill()
        }
        return change
    }
}

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
    func fetch(since: Int64, policy: FecthingPolicy) throws -> SplitChange? {
        self.since = since
        let change = SplitChange()
        change.splits = [Split]()
        change.since = since + 100
        change.till = since + 200
        fetchCallCount+=1
        if let exp = fetchExpectation {
            exp.fulfill()
        }
        return change
    }
}

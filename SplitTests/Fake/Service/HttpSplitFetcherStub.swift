//
//  HttpSplitFetcherStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpSplitFetcherStub: HttpSplitFetcher {
    var splitChanges = [SplitChange?]()
    var httpError: HttpError?
    var hitIndex = 0
    var fetchCallCount: Int = 0
    
    func execute(since: Int64) throws -> SplitChange? {
        fetchCallCount+=1
        if let e = httpError {
            throw e
        }
        let hit = hitIndex
        hitIndex+=1
        if splitChanges.count == 0 {
            return nil
        }

        if splitChanges.count > hit {
            return splitChanges[hit]
        }
        return splitChanges[splitChanges.count - 1]
    }
}

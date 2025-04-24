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
    
    func execute(since: Int64, till: Int64?, headers: HttpHeaders?) throws -> SplitChange {
        fetchCallCount+=1
        if let e = httpError {
            throw e
        }
        let hit = hitIndex
        hitIndex+=1
        if splitChanges.count == 0 {
            throw GenericError.unknown(message: "null feature flag changes")
        }

        if splitChanges.count > hit {
            if let change = splitChanges[hit] {
                return change
            } else {
                throw GenericError.unknown(message: "null feature flag changes")
            }
        }

        if let change = splitChanges[splitChanges.count - 1] {
            return change
        } else {
            throw GenericError.unknown(message: "null split changes")
        }
    }
    
    func executeForTargetingRules(since: Int64, till: Int64?, headers: HttpHeaders?) throws -> TargetingRulesChange {
        // Reuse the existing execute method to get the SplitChange
        let splitChange = try execute(since: since, till: till, headers: headers)
        
        // Create a TargetingRulesChange with the SplitChange as feature flags and empty rule-based segments
        return TargetingRulesChange(
            featureFlags: splitChange,
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)
        )
    }
}

//  SplitsSyncHelperTest.swift
//  Split
// 
//  Created by Martin Cardozo on 29/04/2025.
//  Copyright © 2025 Split. All rights reserved.

import Foundation

import XCTest
@testable import Split

class SplitsSyncHelpersTest: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    
    func testFetchUntilReturnsExpectedResult() throws {
        
        // Storage
        let persistentStorage = PersistentSplitsStorageStub()
        let flagSetsCache     = FlagSetsCacheMock()
        let splitsStorage     = DefaultSplitsStorage(persistentSplitsStorage: persistentStorage, flagSetsCache: flagSetsCache)
        
        let fetcher = HttpSplitFetcherStub()
        
        let helper = SplitsSyncHelper(
            splitFetcher: fetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
            splitChangeProcessor: SplitChangeProcessorStub(),
            splitConfig: SplitClientConfig()
        )
        
        do {
            let _ = try helper.fetchUntil(since: 123, rbSince: 100, clearBeforeUpdate: true)
        } catch {
            
        }

        XCTAssertTrue(fetcher.targetingRulesFetched)
    }
}

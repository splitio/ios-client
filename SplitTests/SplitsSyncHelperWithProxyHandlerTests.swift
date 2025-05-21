//
//  SplitsSyncHelperWithProxyHandlerTests.swift
//  SplitTests
//
//  Created on 14/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitsSyncHelperWithProxyHandlerTests: XCTestCase {

    private var splitFetcher: HttpSplitFetcherMock!
    private var splitsStorage: SplitsStorageStub!
    private var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    private var splitChangeProcessor: SplitChangeProcessorStub!
    private var ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessorStub!
    private var generalInfoStorage: GeneralInfoStorageMock!
    private var splitConfig: SplitClientConfig!
    private var syncHelper: SplitsSyncHelper!

    override func setUp() {
        super.setUp()
        splitFetcher = HttpSplitFetcherMock()
        splitsStorage = SplitsStorageStub()
        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        splitChangeProcessor = SplitChangeProcessorStub()
        ruleBasedSegmentsChangeProcessor = RuleBasedSegmentChangeProcessorStub()
        generalInfoStorage = GeneralInfoStorageMock()
        splitConfig = SplitClientConfig()
        
        syncHelper = SplitsSyncHelper(
            splitFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            splitChangeProcessor: splitChangeProcessor,
            ruleBasedSegmentsChangeProcessor: ruleBasedSegmentsChangeProcessor,
            generalInfoStorage: generalInfoStorage, // Provide storage to enable proxy handling
            splitConfig: splitConfig
        )
    }
    
    func testNormalOperationUsesLatestSpec() throws {
        // Setup fetcher to return successful response
        let targetingRulesChange = createTargetingRulesChange(since: 1, till: 1)
        splitFetcher.targetingRulesChangeToReturn = targetingRulesChange
        
        // Execute sync
        let result = try syncHelper.sync(since: 1, rbSince: 1)
        
        // Verify that the latest spec was used
        XCTAssertEqual(splitFetcher.lastSpecUsed, "1.3")
        XCTAssertTrue(result.success)
    }
    
    func testProxyErrorCausesFallbackToLegacySpec() throws {
        // Setup fetcher to throw outdated proxy error on first call
        splitFetcher.errorToThrow = HttpError.outdatedProxyError(code: 400, spec: "1.3")
        
        do {
            // Execute sync - should throw
            _ = try syncHelper.sync(since: 1, rbSince: 1)
            XCTFail("Should have thrown an error")
        } catch let error as HttpError {
            // Verify that the error is an outdated proxy error
            XCTAssertTrue(error.isProxyOutdatedError())
            
            // Now setup for successful second call with legacy spec
            splitFetcher.errorToThrow = nil
            let targetingRulesChange = createTargetingRulesChange(since: 1, till: 1)
            splitFetcher.targetingRulesChangeToReturn = targetingRulesChange
            
            // Execute sync again
            let result = try syncHelper.sync(since: 1, rbSince: 1)
            
            // Verify that the legacy spec was used and rbSince was omitted
            XCTAssertEqual(splitFetcher.lastSpecUsed, "1.2")
            XCTAssertNil(splitFetcher.lastRbSinceUsed)
            XCTAssertTrue(result.success)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRecoveryModeAfterIntervalElapsed() throws {
        // Setup initial proxy error
        generalInfoStorage.lastProxyUpdateTimestamp = Date.nowMillis() - 3700000 // More than 1 hour ago
        
        // Setup successful response
        let targetingRulesChange = createTargetingRulesChange(since: 1, till: 1)
        splitFetcher.targetingRulesChangeToReturn = targetingRulesChange
        
        // Execute sync
        let result = try syncHelper.sync(since: 1, rbSince: 1)
        
        // Verify that the latest spec was used (recovery mode)
        XCTAssertEqual(splitFetcher.lastSpecUsed, "1.3")
        XCTAssertTrue(result.success)
        
        // Verify that the proxy check timestamp was reset
        XCTAssertEqual(generalInfoStorage.lastProxyUpdateTimestamp, 0)
    }
    
    func testBackgroundSyncAlwaysUsesLatestSpec() throws {
        Spec.flagsSpec = "1.3"
        // Create a background sync helper with no proxy handler
        let bgSyncHelper = SplitsSyncHelper(
            splitFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            splitChangeProcessor: splitChangeProcessor,
            ruleBasedSegmentsChangeProcessor: ruleBasedSegmentsChangeProcessor,
            generalInfoStorage: nil, // Pass nil to disable proxy handling
            splitConfig: splitConfig
        )

        // Setup initial proxy error state
        generalInfoStorage.lastProxyUpdateTimestamp = Date.nowMillis() - 1000 // Recent error

        // Setup successful response
        let targetingRulesChange = createTargetingRulesChange(since: 1, till: 1)
        splitFetcher.targetingRulesChangeToReturn = targetingRulesChange

        // Execute sync
        let result = try bgSyncHelper.sync(since: 1, rbSince: 1)

        XCTAssertEqual(splitFetcher.lastSpecUsed, "1.3")
        XCTAssertNotNil(splitFetcher.lastRbSinceUsed)
        XCTAssertTrue(result.success)
    }
    
    // MARK: - Helper Methods
    
    private func createTargetingRulesChange(since: Int64, till: Int64) -> TargetingRulesChange {
        let splitChange = SplitChange(splits: [], since: since, till: till)
        let rbsChange = RuleBasedSegmentChange(segments: [], since: since, till: till)
        return TargetingRulesChange(featureFlags: splitChange, ruleBasedSegments: rbsChange)
    }
}

// MARK: - Mock Classes

class HttpSplitFetcherMock: HttpSplitFetcher {
    var targetingRulesChangeToReturn: TargetingRulesChange?
    var errorToThrow: Error?
    var lastSinceUsed: Int64?
    var lastRbSinceUsed: Int64?
    var lastTillUsed: Int64?
    var lastSpecUsed: String?
    
    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders?, spec: String?) throws -> TargetingRulesChange {
        lastSinceUsed = since
        lastRbSinceUsed = rbSince
        lastTillUsed = till
        lastSpecUsed = spec
        
        if let error = errorToThrow {
            throw error
        }
        
        guard let targetingRulesChange = targetingRulesChangeToReturn else {
            throw GenericError.unknown(message: "No targeting rules change configured for test")
        }
        
        return targetingRulesChange
    }
}

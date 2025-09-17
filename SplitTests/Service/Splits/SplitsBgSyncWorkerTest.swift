//
//  SplitsBgSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitsBgSyncWorkerTest: XCTestCase {

    var splitFetcher: HttpSplitFetcherStub!
    var splitStorage: PersistentSplitsStorageStub!
    var persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub!
    var splitChangeProcessor: SplitChangeProcessorStub!
    var ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessorStub!
    var splitsSyncWorker: BackgroundSyncWorker!
    var generalInfoStorage = GeneralInfoStorageMock()

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitStorage = PersistentSplitsStorageStub()
        persistentRuleBasedSegmentsStorage = PersistentRuleBasedSegmentsStorageStub()
        splitStorage.changeNumber = 100
        let _ = SplitChange(splits: [], since: splitStorage.changeNumber, till: splitStorage.changeNumber)
        splitChangeProcessor = SplitChangeProcessorStub()
        ruleBasedSegmentChangeProcessor = RuleBasedSegmentChangeProcessorStub()
    }

    func testFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitFetcher,
                                                      persistentSplitsStorage: splitStorage,
                                                      persistentRuleBasedSegmentsStorage: persistentRuleBasedSegmentsStorage,
                                                      splitChangeProcessor: splitChangeProcessor,
                                                      ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                      cacheExpiration: 100,
                                                      splitConfig: SplitClientConfig(),
                                                      generalInfoStorage: generalInfoStorage)

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [TargetingRulesChange(featureFlags: change)]

        splitsSyncWorker.execute()

        XCTAssertFalse(splitStorage.clearCalled)
        XCTAssertNotNil(splitStorage.processedSplitChange)
    }

    func testFetchFail() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitFetcher,
                                                      persistentSplitsStorage: splitStorage,
                                                      persistentRuleBasedSegmentsStorage: persistentRuleBasedSegmentsStorage,
                                                      splitChangeProcessor: splitChangeProcessor,
                                                      ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                      cacheExpiration: 100,
                                                      splitConfig: SplitClientConfig(),
                                                      generalInfoStorage: generalInfoStorage)

        splitFetcher.httpError = HttpError.clientRelated(code: -1, internalCode: -1)

        splitsSyncWorker.execute()

        XCTAssertFalse(splitStorage.clearCalled)
        XCTAssertNil(splitStorage.processedSplitChange)
    }

    func testNoClearNonExpiredCache() {

        let expiration = 1000
        splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitFetcher,
                                                      persistentSplitsStorage: splitStorage,
                                                      persistentRuleBasedSegmentsStorage: persistentRuleBasedSegmentsStorage,
                                                      splitChangeProcessor: splitChangeProcessor,
                                                      ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                      cacheExpiration: 2000,
                                                      splitConfig: SplitClientConfig(),
                                                      generalInfoStorage: generalInfoStorage)
        
        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Date().timeIntervalSince1970) - Int64(expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [TargetingRulesChange(featureFlags: change)]
        splitsSyncWorker.execute()

        XCTAssertFalse(splitStorage.clearCalled)
    }

    override func tearDown() {
    }

    private func createSplit(name: String) -> Split {
        return SplitTestHelper.newSplit(name: name, trafficType: "tt1")
    }

}

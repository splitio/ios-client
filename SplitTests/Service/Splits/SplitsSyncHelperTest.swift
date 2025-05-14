//
//  SplitsSyncHelperTest.swift
//  SplitTests
//
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

final class SplitsSyncHelperTest: XCTestCase {

    private var syncHelper: SplitsSyncHelper!
    private var splitFetcher: HttpSplitFetcherStub!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                      splitsStorage: SplitsStorageStub(),
                                      ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                      splitChangeProcessor: SplitChangeProcessorStub(),
                                      ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessorStub(),
                                      generalInfoStorage: GeneralInfoStorageMock(),
                                      splitConfig: SplitClientConfig())
    }

    func testRbSinceParamIsSentToFetcher() {
        do {
            _ = try syncHelper.sync(since: 120, rbSince: 130)
        } catch {
            // ignore; we only care about param values
        }

        XCTAssertEqual(120, splitFetcher.params["since"], "since is not 120")
        XCTAssertEqual(130, splitFetcher.params["rbSince"], "rbSince is not 130")
        XCTAssertEqual(nil, splitFetcher.params["til"], "till is not nil")
    }
}

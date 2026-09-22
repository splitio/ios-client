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

final class SplitsProxyRecoveryTests: XCTestCase {
    func testRecoveryRefetchesUnchangedDefinitions() throws {
        let fixture = ProxyRecoveryFixture()
        let flag = SplitTestHelper.newSplit(name: "unchanged_flag", trafficType: "user")
        flag.status = .active
        let segment = RuleBasedSegment(name: "unchanged_segment")
        fixture.flags.updateWithoutChecks(split: flag)
        fixture.segments.segments["unchanged_segment"] = segment

        fixture.fetcher.error = HttpError.outdatedProxyError(code: -1005, spec: "1.3")
        XCTAssertThrowsError(try fixture.helper().sync(since: 100, rbSince: 200))
        XCTAssertGreaterThan(fixture.info.lastProxyUpdateTimestamp, 0)

        fixture.fetcher.error = nil
        fixture.fetcher.response = { since, rbSince, _ in
            fixture.change(since: since, rbSince: rbSince,
                           flags: since == -1 ? [flag] : [],
                           segments: rbSince == -1 ? [segment] : [])
        }
        XCTAssertTrue(try fixture.helper().sync(since: 100, rbSince: 200).success)
        XCTAssertNotNil(fixture.flags.get(name: "unchanged_flag"))

        fixture.info.lastProxyUpdateTimestamp = Date.nowMillis() - 3_700_000
        fixture.fetcher.requests.removeAll()
        XCTAssertTrue(try fixture.helper().sync(since: 100, rbSince: 200).success)

        XCTAssertEqual(fixture.fetcher.requests.first?.since, -1)
        XCTAssertEqual(fixture.fetcher.requests.first?.rbSince, -1)
        XCTAssertNotNil(fixture.flags.get(name: "unchanged_flag"))
        XCTAssertNotNil(fixture.segments.get(segmentName: "unchanged_segment"))
        XCTAssertEqual(fixture.flags.clearCalledTimes, 1)
        XCTAssertEqual(fixture.info.lastProxyUpdateTimestamp, 0)
    }

    func testRecoveryKeepsSnapshotThroughPollingAndCdnRetry() throws {
        for maxAttempts in [1, 2] {
            let fixture = ProxyRecoveryFixture()
            fixture.config.cdnByPassMaxAttempts = maxAttempts
            fixture.config.cdnBackoffTimeBaseInSecs = 0
            fixture.config.cdnBackoffTimeMaxInSecs = 0
            fixture.info.lastProxyUpdateTimestamp = Date.nowMillis() - 3_700_000
            let flag = SplitTestHelper.newSplit(name: "snapshot_flag", trafficType: "user")
            flag.status = .active
            let segment = RuleBasedSegment(name: "snapshot_segment")
            var fetchCount = 0
            fixture.fetcher.response = { since, rbSince, _ in
                fetchCount += 1
                return fixture.change(since: since, rbSince: rbSince,
                                      till: fetchCount < 3 ? 100 : 200,
                                      rbTill: fetchCount < 3 ? 100 : 200,
                                      flags: fetchCount == 1 ? [flag] : [],
                                      segments: fetchCount == 1 ? [segment] : [])
            }

            XCTAssertTrue(try fixture.helper().sync(since: 100, rbSince: 100,
                                                    till: 200, rbTill: 200).success)
            XCTAssertNotNil(fixture.flags.get(name: "snapshot_flag"))
            XCTAssertNotNil(fixture.segments.get(segmentName: "snapshot_segment"))
            XCTAssertEqual(fixture.flags.clearCalledTimes, 1)
            XCTAssertEqual(fixture.info.lastProxyUpdateTimestamp, 0)
            XCTAssertEqual(fixture.fetcher.lastTill, maxAttempts == 1 ? 100 : nil)
        }
    }
}

private final class ProxyRecoveryFixture {
    let fetcher = ProxyRecoveryFetcher()
    let flags = SplitsStorageStub()
    let segments = RuleBasedSegmentsStorageStub()
    let info = GeneralInfoStorageMock()
    let config = SplitClientConfig()

    func helper() -> SplitsSyncHelper {
        SplitsSyncHelper(splitFetcher: fetcher,
                         splitsStorage: flags,
                         ruleBasedSegmentsStorage: segments,
                         splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
                         ruleBasedSegmentsChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
                         generalInfoStorage: info,
                         splitConfig: config)
    }

    func change(since: Int64, rbSince: Int64?,
                till: Int64 = 100, rbTill: Int64 = 200,
                flags: [Split] = [], segments: [RuleBasedSegment] = []) -> TargetingRulesChange {
        TargetingRulesChange(
            featureFlags: SplitChange(splits: flags, since: since, till: till),
            ruleBasedSegments: RuleBasedSegmentChange(segments: segments,
                                                       since: rbSince ?? rbTill, till: rbTill))
    }
}

private final class ProxyRecoveryFetcher: HttpSplitFetcher, @unchecked Sendable {
    var error: Error?
    var response: ((Int64, Int64?, Int64?) -> TargetingRulesChange)?
    var requests: [(since: Int64, rbSince: Int64?)] = []
    var lastTill: Int64?

    func execute(since: Int64, rbSince: Int64?, till: Int64?,
                 headers: HttpHeaders?, spec: String?) throws -> TargetingRulesChange {
        requests.append((since, rbSince))
        lastTill = till
        if let error { throw error }
        guard let response else { throw GenericError.unknown(message: "No test response") }
        return response(since, rbSince, till)
    }
}

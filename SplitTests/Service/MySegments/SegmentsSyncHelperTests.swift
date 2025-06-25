//
//  SegmentsSyncHelperTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/09/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest

import XCTest
@testable import Split

class SegmentsSyncHelperTests: XCTestCase {

    var mySegmentsFetcher: HttpMySegmentsFetcherStub!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!
    var myLargeSegmentsStorage: ByKeyMySegmentsStorageStub!
    let userKey = IntegrationHelper.dummyUserKey
    var config: SplitClientConfig!
    var changeChecker: MySegmentsChangesCheckerMock!
    var syncHelper: DefaultSegmentsSyncHelper!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        myLargeSegmentsStorage = ByKeyMySegmentsStorageStub()
        config = SplitClientConfig()
        config.cdnByPassMaxAttempts = 2
        config.cdnBackoffTimeBaseInSecs = 1
        config.cdnBackoffTimeMaxInSecs = 1
        changeChecker = MySegmentsChangesCheckerMock()
        syncHelper = DefaultSegmentsSyncHelper(userKey: userKey,
                                        segmentsFetcher: mySegmentsFetcher,
                                        mySegmentsStorage: mySegmentsStorage,
                                        myLargeSegmentsStorage: myLargeSegmentsStorage,
                                        changeChecker: changeChecker,
                                        splitConfig: config)
    }

    func testCdnByPassNoTillNoChange() throws {
        try cdnByPassNoTill(segmentsChanged: [])
    }

    func testCdnByPassNoTillChange() throws {
        try cdnByPassNoTill(segmentsChanged: ["Segment1"])
    }

    func cdnByPassNoTill(segmentsChanged: [String]) throws {
        let goalCn: Int64 = 300
        mySegmentsStorage.changeNumber = 200
        myLargeSegmentsStorage.changeNumber = 200
        changeChecker.haveChanged = !segmentsChanged.isEmpty
        changeChecker.segmentsDiff = segmentsChanged

        let exp = XCTestExpectation()
        mySegmentsFetcher.countExp = exp
        mySegmentsFetcher.limitCountExp = 3

        mySegmentsFetcher.segments = TestingHelper.buildSegmentsChange(count: 3,
                                                                       mlsAscOrder: false,
                                                                       segmentsChanged: segmentsChanged)
        let res = try syncHelper.sync(msTill: goalCn, mlsTill: goalCn, headers: nil)

        sleep(1)

        wait(for: [exp], timeout: 3.0)
        XCTAssertEqual(3, mySegmentsFetcher.fetchMySegmentsCount)
        XCTAssertEqual(userKey, mySegmentsFetcher.lastUserKey)
        XCTAssertNil(mySegmentsFetcher.lastTill)
        XCTAssertTrue(res.success)
        XCTAssertEqual(res.msUpdated, segmentsChanged)
        XCTAssertEqual(res.mlsUpdated, segmentsChanged)
        XCTAssertEqual(301, res.msChangeNumber)
        XCTAssertEqual(301, res.mlsChangeNumber)
    }

    func testCdnByPassTill() throws {
        // To avoid looping with backoff
        config.cdnByPassMaxAttempts = 1
        let storedCn: Int64 = 300
        mySegmentsStorage.changeNumber = storedCn
        myLargeSegmentsStorage.changeNumber = storedCn
        changeChecker.haveChanged = true

        let exp = XCTestExpectation()
        mySegmentsFetcher.countExp = exp
        mySegmentsFetcher.limitCountExp = 6

        var segments = [AllSegmentsChange]()
        let halfCount = 3
        // Here should loop through this values
        var msCn: Int64 = 0
        var mlsCn: Int64 = 0

        for i in 0..<halfCount {
            msCn = Int64(50 - i)
            mlsCn = Int64(62 - i)
            segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: msCn, mls: ["ls1"], mlsCn: mlsCn))
        }
        // Same value should make go out from the first fetch
        segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: msCn, mls: ["ls1"], mlsCn: mlsCn))

        // Until this value
        // The fetch here should be including a till value
        segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: msCn, mls: ["ls1"], mlsCn: mlsCn))
        segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: 400, mls: ["ls1"], mlsCn: 500))
        mySegmentsFetcher.segments = segments

        let res = try syncHelper.sync(msTill: storedCn, mlsTill: storedCn, headers: nil)

        sleep(1)
        wait(for: [exp], timeout: 4.0)
        XCTAssertEqual(6, mySegmentsFetcher.fetchMySegmentsCount)
        XCTAssertEqual(userKey, mySegmentsFetcher.lastUserKey)
        XCTAssertNotNil(mySegmentsFetcher.lastTill)
        XCTAssertEqual(400, res.msChangeNumber)
        XCTAssertEqual(500, res.mlsChangeNumber)

    }

    func testDidffGoallCnMs() throws {
        try diffGoalCnTest(msCnBigger: true)
    }

    func testDiffGoalCnMls() throws {
        try diffGoalCnTest(msCnBigger: false)
    }

    func diffGoalCnTest(msCnBigger: Bool) throws {
        mySegmentsStorage.changeNumber = 200
        myLargeSegmentsStorage.changeNumber = 200

        let exp = XCTestExpectation()
        mySegmentsFetcher.countExp = exp
        mySegmentsFetcher.limitCountExp = 4

        var segments = [AllSegmentsChange]()
        segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: 190, mls: ["ls1"], mlsCn: 200))
        segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: 160, mls: ["ls1"], mlsCn: 400))

        let goalMsCn = 400.asInt64()
        let goalMlsCn = 500.asInt64()
        if msCnBigger {
            segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: goalMsCn, mls: ["ls1"], mlsCn: 400))
            segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: goalMsCn, mls: ["ls1"], mlsCn: goalMlsCn))
        } else {
            segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: 300, mls: ["ls1"], mlsCn: goalMlsCn))
            segments.append(TestingHelper.newAllSegmentsChange(ms: ["s1"], msCn: goalMsCn, mls: ["ls1"], mlsCn: goalMlsCn))
        }
        mySegmentsFetcher.segments = segments

        let res = try syncHelper.sync(msTill: goalMsCn, mlsTill: goalMlsCn, headers: nil)

        wait(for: [exp], timeout: 3.0)
        XCTAssertEqual(4, mySegmentsFetcher.fetchMySegmentsCount)
        XCTAssertEqual(userKey, mySegmentsFetcher.lastUserKey)
        XCTAssertNil(mySegmentsFetcher.lastTill)
        XCTAssertTrue(res.success)
        XCTAssertEqual(goalMsCn, res.msChangeNumber)
        XCTAssertEqual(goalMlsCn, res.mlsChangeNumber)
    }
}



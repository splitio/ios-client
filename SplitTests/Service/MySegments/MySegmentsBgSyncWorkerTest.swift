//
//  MySegmentsBgSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class MySegmentsBgSyncWorkerTest: XCTestCase {
    var mySegmentsFetcher: HttpMySegmentsFetcherStub!
    var mySegmentsStorage: PersistentMySegmentsStorageMock!
    var myLargeSegmentsStorage: PersistentMySegmentsStorageMock!
    var mySegmentsSyncWorker: BackgroundSyncWorker!
    let userKey = "CUSTOMER_ID"

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = PersistentMySegmentsStorageMock()
        myLargeSegmentsStorage = PersistentMySegmentsStorageMock()

        mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
            userKey: userKey,
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage,
            myLargeSegmentsStorage: myLargeSegmentsStorage)
    }

    func testOneTimeFetchSuccess() {
        mySegmentsFetcher.segments = segments()
        mySegmentsSyncWorker.execute()

        XCTAssertNotNil(mySegmentsStorage.persistedSegments[userKey])
    }

    func testNoSuccess() {
        mySegmentsFetcher.httpError = HttpError.clientRelated(code: -1, internalCode: -1)
        mySegmentsFetcher.segments = segments()
        mySegmentsSyncWorker.execute()

        XCTAssertNil(mySegmentsStorage.persistedSegments[userKey])
    }

    func segments() -> [AllSegmentsChange] {
        let msChange = SegmentChange(segments: ["s1", "s2"])
        let mlsChange = SegmentChange(segments: ["s1", "s2"])
        return [AllSegmentsChange(
            mySegmentsChange: msChange,
            myLargeSegmentsChange: mlsChange)]
    }
}

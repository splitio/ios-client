//
//  MySegmentsBgSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsBgSyncWorkerTest: XCTestCase {

    var mySegmentsFetcher: HttpMySegmentsFetcherStub!
    var mySegmentsStorage: PersistentMySegmentsStorageStub!
    var myLargeSegmentsStorage: PersistentMyLargeSegmentsStorageMock!
    var mySegmentsSyncWorker: BackgroundSyncWorker!
    let userKey = "CUSTOMER_ID"

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = PersistentMySegmentsStorageStub()
        myLargeSegmentsStorage = PersistentMyLargeSegmentsStorageMock()

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
        return [AllSegmentsChange(mySegmentsChange: msChange,
                                  myLargeSegmentsChange: mlsChange)]
    }
}

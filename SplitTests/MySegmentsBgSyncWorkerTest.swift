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
    var mySegmentsSyncWorker: BackgroundSyncWorker!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = PersistentMySegmentsStorageStub()

        mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
            userKey: "CUSTOMER_ID",
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage)
    }

    func testOneTimeFetchSuccess() {

        mySegmentsFetcher.allSegments = [["s1", "s2"]]
        mySegmentsSyncWorker.execute()

        XCTAssertNotNil(mySegmentsStorage.segments)
    }


    func testNoSuccess() {

        mySegmentsFetcher.httpError = HttpError.clientRelated
        mySegmentsFetcher.allSegments = [["s1", "s2"]]
        mySegmentsSyncWorker.execute()

        XCTAssertEqual(0, mySegmentsStorage.segments.count)
    }

    override func tearDown() {
    }
}

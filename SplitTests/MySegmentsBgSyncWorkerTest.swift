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
    var mySegmentsStorage: MySegmentsStorageStub!
    var mySegmentsSyncWorker: BackgroundSyncWorker!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = MySegmentsStorageStub()

        mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
            userKey: "CUSTOMER_ID",
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage)
    }

    func testOneTimeFetchSuccess() {

        mySegmentsFetcher.allSegments = [["s1", "s2"]]
        mySegmentsSyncWorker.execute()

        XCTAssertNotNil(mySegmentsStorage.updatedSegments)
    }


    func testNoSuccess() {

        mySegmentsFetcher.httpError = HttpError.clientRelated
        mySegmentsFetcher.allSegments = [["s1", "s2"]]
        mySegmentsSyncWorker.execute()

        XCTAssertNil(mySegmentsStorage.updatedSegments)
    }

    override func tearDown() {
    }
}

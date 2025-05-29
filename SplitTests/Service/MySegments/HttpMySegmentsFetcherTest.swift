//
//  HttpMySegmentsFetcherTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpMySegmentsFetcherTest: XCTestCase {
    var restClient: RestClientStub!
    var fetcher: HttpMySegmentsFetcher!
    var telemetryProducer: TelemetryStorageStub!
    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        fetcher = DefaultHttpMySegmentsFetcher(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(userKey: "user", till: nil, headers: nil)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessFulFetch() throws {
        restClient.isServerAvailable = true
        let change = SegmentChange(segments: ["s1", "s2", "s3"], changeNumber: 100)
        let largeChange = SegmentChange(segments: ["s2", "s4"], changeNumber: 200)
        let allChange = AllSegmentsChange(
            mySegmentsChange: change,
            myLargeSegmentsChange: largeChange)
        restClient.update(segments: [allChange])

        let c = try fetcher.execute(userKey: "user", till: nil, headers: nil)
        let sc = c?.mySegmentsChange
        let lc = c?.myLargeSegmentsChange

        XCTAssertEqual(3, sc?.segments.count)
        XCTAssertEqual(100, sc?.changeNumber)
        XCTAssertEqual(2, lc?.segments.count)
        XCTAssertEqual(100, sc?.changeNumber)
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }
}

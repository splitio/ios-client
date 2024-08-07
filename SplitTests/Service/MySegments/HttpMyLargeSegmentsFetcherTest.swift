//
//  HttpMyLargeSegmentsFetcherTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpMyLargeSegmentsFetcherTest: XCTestCase {
    
    var restClient: RestClientStub!
    var fetcher: HttpMyLargeSegmentsFetcher!
    var telemetryProducer: TelemetryStorageStub!
    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        fetcher = HttpMyLargeSegmentsFetcher(restClient: restClient,
                                             syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }
    
    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try fetcher.execute(userKey: "user", headers: nil)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }
    
    func testSuccessFulFetch() throws {
        restClient.isServerAvailable = true
        restClient.update(largeSegments: [SegmentChange(segments: ["s1", "s2", "s3"], changeNumber: 100)])

        let c = try fetcher.execute(userKey: "user", headers: nil)
        
        XCTAssertEqual(3, c?.segments.count)
        XCTAssertEqual(100, c?.changeNumber)
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }
}


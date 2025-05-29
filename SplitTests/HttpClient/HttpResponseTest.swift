//
//  HttpResponseTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 24/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpResponseTest: XCTestCase {
    override func setUp() {}

    func testHttp200() {
        // Create http response code > 200 and < 300 should be SUCCESS
        let response = HttpResponse(code: 200)

        XCTAssertTrue(response.result.isSuccess)
    }

    func testHttp299() {
        // Create http response code > 200 and < 300 should be SUCCESS
        // Put some values in input stream (from output stream anywhere)
        // Check values received
        let response = HttpResponse(code: 299)

        XCTAssertTrue(response.result.isSuccess)
    }

    func testHttp104() {
        // Http 104-199 is unassgned so far
        // Create http response code < 104 should not be considered SUCCESSs
        let response = HttpResponse(code: 104)

        XCTAssertFalse(response.result.isSuccess)
    }

    func testHttp300() {
        // Create http response code > 299 should be considered ERROR
        let response = HttpResponse(code: 300)

        XCTAssertFalse(response.result.isSuccess)
    }

    override func tearDown() {}
}

//  HttpResponseTest
//  Created by Javier L. Avrudsky on 24/06/2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation
import XCTest
@testable import Http

class HttpResponseTest: XCTestCase {
    override func setUp() {
    }

    func testHttp200() {
        // Create http response code > 200 and < 300 should be SUCCESS
        let response = HttpResponse(code: 200)

        XCTAssertTrue(response.isSuccess)
    }

    func testHttp299() {
        // Create http response code > 200 and < 300 should be SUCCESS
        let response = HttpResponse(code: 299)

        XCTAssertTrue(response.isSuccess)
    }

    func testHttp104() {
        // Http 104-199 is unassigned so far
        // Create http response code < 104 should not be considered SUCCESS
        let response = HttpResponse(code: 104)

        XCTAssertFalse(response.isSuccess)
    }

    func testHttp300() {
        // Create http response code > 299 should be considered ERROR
        let response = HttpResponse(code: 300)

        XCTAssertFalse(response.isSuccess)
    }


    override func tearDown() {
    }
}

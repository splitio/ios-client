//
//  HttpRequestListTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpRequestListTest: XCTestCase {
    var requestList: HttpRequestList!
    override func setUp() {
        requestList = HttpRequestList()
    }

    func testAddRequest() {
        requestList.set(HttpRequestMock(identifier: 1))
        requestList.set(HttpRequestMock(identifier: 2))

        let r1 = requestList.take(identifier: 1)
        let r2 = requestList.take(identifier: 2)

        XCTAssertNotNil(r1)
        XCTAssertNotNil(r2)
    }

    func testTakeRequest() {
        requestList.set(HttpRequestMock(identifier: 1))
        requestList.set(HttpRequestMock(identifier: 2))

        let r1 = requestList.take(identifier: 1)
        let r1bis = requestList.take(identifier: 1)

        XCTAssertNotNil(r1)
        XCTAssertNil(r1bis)
    }

    func testOverrideSetRequest() {
        let r1 = HttpRequestMock(identifier: 1)
        r1.method = .get
        requestList.set(r1)

        let r1Post = HttpRequestMock(identifier: 1)
        r1Post.method = .post
        requestList.set(r1Post)

        let r = requestList.take(identifier: 1)

        XCTAssertEqual(HttpMethod.post, r?.method)
    }

    override func tearDown() {}
}

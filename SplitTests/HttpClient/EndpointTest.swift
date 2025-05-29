//
//  EndpointTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class EndpointTest: XCTestCase {
    static let kTestUrlString = "https://www.dummy-split.com"
    static let kTestPath = "splits"
    let kTestUrl = URL(string: kTestUrlString)!
    let kFullUrl = URL(string: "\(kTestUrlString)/\(kTestPath)")!

    override func setUp() {}

    func testDefaultEndpointBuild() {
        let endpoint = Endpoint.builder(baseUrl: kTestUrl, path: Self.kTestPath).build()

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(0, endpoint.headers.count)
        XCTAssertEqual(kFullUrl, endpoint.url)
    }

    func testPostEndpointBuild() {
        let endpoint = Endpoint.builder(baseUrl: kTestUrl, path: Self.kTestPath)
            .set(method: .post)
            .build()

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(kFullUrl, endpoint.url)
    }

    func testHeadersEndpointBuild() {
        let endpoint = Endpoint.builder(baseUrl: kTestUrl, path: Self.kTestPath)
            .add(headers: ["header1": "value1", "header2": "value2"])
            .add(header: "header3", withValue: "value3")
            .build()

        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual("value1", endpoint.headers["header1"])
        XCTAssertEqual("value2", endpoint.headers["header2"])
        XCTAssertEqual("value3", endpoint.headers["header3"])
        XCTAssertEqual(kFullUrl, endpoint.url)
    }

    override func tearDown() {}
}

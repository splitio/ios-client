//
//  EnvironmentTargetManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation


import XCTest
@testable import Split

class EnvironmentTargetManagerTest: XCTestCase {
    var url: URL!
    override func setUp() {
        url = URL(string: "http://www.split.com")
    }

    func testEmptySplitsFilterQueryString() {

        let target = DynamicTarget(
            url, url, DynamicTarget.DynamicTargetStatus.getSplitChanges(since: -1, queryString: ""))

        XCTAssertEqual("\(url.absoluteString)/splitChanges?since=-1", target.url.absoluteString)

    }

    func testSimpleSplitsFilterQueryString() {
        let qs = "&p1=v1,v2,v3&p2=v1,v2,v3"
        let target = DynamicTarget(
            url, url, DynamicTarget.DynamicTargetStatus.getSplitChanges(since: -1, queryString: qs))

        XCTAssertEqual("\(url.absoluteString)/splitChanges?since=-1\(qs)", target.url.absoluteString)

    }

    override func tearDown() {
    }
}

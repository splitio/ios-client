//
//  MySegmentsPayloadDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class MySegmentsPayloadDecoderTest: XCTestCase {
    let decoder = DefaultMySegmentsPayloadDecoder()

    override func setUp() {}

    func testUserKeyHash() {
        let expectedResult = "MjAwNjI0Nzg3NQ=="

        XCTAssertEqual(expectedResult, decoder.hash(userKey: "user_key"))
    }

    override func tearDown() {}
}

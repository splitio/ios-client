//
//  MySegmentsV2PayloaDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsV2PayloaDecoderTest: XCTestCase {

    let decoder = DefaultMySegmentsV2PayloadDecoder()
    let gzip = Gzip()

    override func setUp() {
    }

    func testKeyListGzipPayload() throws {

        let payload = try decoder.decodeAsString(payload: TestingData.encodedKeyListPayloadGzip(),
                                                 compressionUtil: gzip)

        let keyList = decoder.parseKeyList(jsonString: payload)

        let added = keyList?.added
        let removed = keyList?.removed

        XCTAssertEqual(2, added?.count)
        XCTAssertEqual(2, removed?.count)
        XCTAssertTrue(added?.contains(1573573083296714675) ?? false)
        XCTAssertTrue(added?.contains(8482869187405483569) ?? false)
        XCTAssertTrue(removed?.contains(8031872927333060586) ?? false)
        XCTAssertTrue(removed?.contains(6829471020522910836) ?? false)

    }

    override func tearDown() {
    }
}


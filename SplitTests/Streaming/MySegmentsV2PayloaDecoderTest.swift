//
//  MySegmentsV2PayloaDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class MySegmentsV2PayloaDecoderTest: XCTestCase {
    let decoder = DefaultSegmentsPayloadDecoder()
    let gzip = Gzip()
    let zlib = Zlib()

    func testKeyListGzipPayload() throws {
        let payload = try decoder.decodeAsString(
            payload: TestingData.encodedKeyListPayloadGzip(),
            compressionUtil: gzip)

        let keyList = try decoder.parseKeyList(jsonString: payload)

        let added = keyList.added
        let removed = keyList.removed

        XCTAssertEqual(2, added.count)
        XCTAssertEqual(2, removed.count)
        XCTAssertTrue(added.contains(1573573083296714675))
        XCTAssertTrue(added.contains(8482869187405483569))
        XCTAssertTrue(removed.contains(8031872927333060586))
        XCTAssertTrue(removed.contains(6829471020522910836))
    }

    func testBoundedGzipPayload() throws {
        let payload = try decoder.decodeAsBytes(payload: TestingData.encodedBoundedPayloadGzip(), compressionUtil: gzip)
        try boundedTest(payload: payload, decompressor: gzip)
    }

    func testBoundedZlibPayload() throws {
        let payload = try decoder.decodeAsBytes(payload: TestingData.encodedBoundedPayloadZlib(), compressionUtil: zlib)
        try boundedTest(payload: payload, decompressor: zlib)
    }

    func boundedTest(payload: Data, decompressor: CompressionUtil) throws {
        var keys = [String]()
        keys.append("603516ce-1243-400b-b919-0dce5d8aecfd")
        keys.append("88f8b33b-f858-4aea-bea2-a5f066bab3ce")
        keys.append("375903c8-6f62-4272-88f1-f8bcd304c7ae")
        keys.append("18c936ad-0cd2-490d-8663-03eaa23a5ef1")
        keys.append("bfd4a824-0cde-4f11-9700-2b4c5ad6f719")
        keys.append("4588c4f6-3d18-452a-bc4a-47d7abfd23df")
        keys.append("42bcfe02-d268-472f-8ed5-e6341c33b4f7")
        keys.append("2a7cae0e-85a2-443e-9d7c-7157b7c5960a")
        keys.append("4b0b0467-3fe1-43d1-a3d5-937c0a5473b1")
        keys.append("09025e90-d396-433a-9292-acef23cf0ad1")

        var results = [String: Bool]()
        for key in keys {
            let hashedKey = decoder.hashKey(key)
            results[key] = decoder.isKeyInBitmap(keyMap: payload, hashedKey: hashedKey)
        }

        for key in keys {
            XCTAssertTrue(results[key] ?? false)
        }
    }

    override func tearDown() {}
}

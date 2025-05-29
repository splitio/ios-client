//
//  DecompressionTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

@testable import Split

class DecompressionTest: XCTestCase {
    let zlib = Zlib()
    let gzip = Gzip()

    override func setUp() {}

    func testLoremIpsumZlib() {
        let lines = loadLoremIpsumZlib()
        let expected = loadLoremIpsumExpected()
        var results = [String]()
        for line in lines {
            results.append(descompressZlib(line))
        }

        for (i, result) in results.enumerated() {
            XCTAssertEqual(expected[i], result)
        }
    }

    func testLoremIpsumGzip() {
        let lines = loadLoremIpsumGzip()
        let expected = loadLoremIpsumExpected()
        var results = [String]()
        for line in lines {
            results.append(descompressGzip(line))
        }

        for (i, result) in results.enumerated() {
            XCTAssertEqual(expected[i], result)
        }
    }

    func testZlibCompressionMethodHeader() {
        // Byte 2 => compression method should be 8, else error.
        let data1 = Data([31, 139, 9, 0, 1, 1, 0])

        let size1 = gzip.checkAndGetHeaderSize(data: data1)

        XCTAssertEqual(-1, size1)
    }

    func testGzipIncorrectHeader() {
        // Byte 0, 1
        // Header should start with 31, 139, gzip IDs (0x1f, 0x8b)
        let data1 = Data([20, 139, 8, 0, 1, 1, 0])
        let data2 = Data([31, 20, 8, 0, 1, 1, 0])

        let size1 = gzip.checkAndGetHeaderSize(data: data1)
        let size2 = gzip.checkAndGetHeaderSize(data: data2)

        XCTAssertEqual(-1, size1)
        XCTAssertEqual(-1, size2)
    }

    func testGzipCompressionMethodHeader() {
        // Byte 2 => compression method should be 8, else error.
        let data1 = Data([31, 139, 9, 0, 1, 1, 0])

        let size1 = gzip.checkAndGetHeaderSize(data: data1)

        XCTAssertEqual(-1, size1)
    }

    func testGzipHeaderExtraField() {
        let data = dataWithHeaders(extraField: true, fileName: false, crc16: false, comment: false)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(19, size)
    }

    func testGzipHeaderFileName() {
        let data = dataWithHeaders(extraField: false, fileName: true, crc16: false, comment: false)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(15, size)
    }

    func testGzipHeaderComments() {
        let data = dataWithHeaders(extraField: false, fileName: false, crc16: false, comment: true)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(15, size)
    }

    func testGzipHeaderCrc16() {
        let data = dataWithHeaders(extraField: false, fileName: false, crc16: true, comment: false)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(12, size)
    }

    func testGzipAllHeaders() {
        let data = dataWithHeaders(extraField: true, fileName: true, crc16: true, comment: true)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(31, size)
    }

    override func tearDown() {}

    private func loadLoremIpsumZlib() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum_zlib", type: "txt") else {
            print("Error loading compression test Data.")
            XCTAssertTrue(false)
            return []
        }
        return data.split(separator: "\n").map { String($0) }
    }

    private func loadLoremIpsumGzip() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum_gzip", type: "txt") else {
            print("Error loading compression test Data.")
            XCTAssertTrue(false)
            return []
        }
        return data.split(separator: "\n").map { String($0) }
    }

    private func loadLoremIpsumExpected() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum_result", type: "txt") else {
            print("Error loading compression test Data.")
            XCTAssertTrue(false)
            return []
        }
        return data.split(separator: "\n").map { String($0) }
    }

    func testHeaderFlag0() {
        let data = dataWithHeaders(extraField: false, fileName: false, crc16: false, comment: false)
        let size = gzip.checkAndGetHeaderSize(data: data)
        XCTAssertEqual(10, size)
    }

    func dataWithHeaders(extraField: Bool, fileName: Bool, crc16: Bool, comment: Bool) -> Data {
        var flag: UInt8 = 0
        // Id1, id2, cm, flag
        var h1: [UInt8] = [31, 139, 8, 0]
        // Rest of header that would be ignored while analisis
        h1.append(contentsOf: [1, 2, 3, 4, 5, 6])

        if extraField {
            flag |= UInt8(1 << 2)
            // 1, 1 (S1, S2). size (2 bytes) = 5, 0 (little endian) and byte extra after 0
            h1.append(contentsOf: [1, 1, 5, 0, 1, 2, 3, 4, 5])
        }

        if fileName {
            flag |= UInt8(1 << 3)
            h1.append(contentsOf: [1, 2, 3, 4, 0])
        }

        if comment {
            flag |= UInt8(1 << 4)
            h1.append(contentsOf: [1, 2, 3, 4, 0])
        }

        if crc16 {
            flag |= UInt8(1 << 1)
            h1.append(contentsOf: [1, 2])
        }

        // Update flag value

        h1[3] = flag
        // Simulate data (not reaaly needed)
        h1.append(contentsOf: [1, 2, 3, 4, 5, 6, 7, 8, 9, 0])

        return Data(h1)
    }

    func descompressGzip(_ base64: String) -> String {
        guard let dec = Base64Utils.decodeBase64(base64) else { return "" }

        guard let descomp = try? gzip.decompress(data: dec) else {
            return ""
        }
        return descomp.stringRepresentation
    }

    func descompressZlib(_ base64: String) -> String {
        guard let dec = Base64Utils.decodeBase64(base64) else { return "" }

        guard let descomp = try? zlib.decompress(data: dec) else {
            return ""
        }
        return descomp.stringRepresentation
    }
}

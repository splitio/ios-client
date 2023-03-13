//
//  CipherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

import XCTest
@testable import Split

class CipherTest: XCTestCase {

    let cipher = DefaultCipher()

    override func setUp() {
    }

    func testBasicEncryptDecrypt() {
        encryptDecryptTest(originalText: "javier", key: String(repeating: "k", count: 32))
    }

    func testJsonSplitEncryptDecrypt() {
        let text = TestDataHelper.jsonSplitSample
        let key = String(UUID().uuidString.prefix(32))
        encryptDecryptTest(originalText: text, key: key)
    }

    func testMySegmentsEncryptDecrypt() {
        let text = "segment1, segment2, segment_4, segment%5, segment-6, segment!7, segment#8, segment@9, segment_what"
        let key = String(UUID().uuidString.prefix(32))
        encryptDecryptTest(originalText: text, key: key)
    }
    func testImpressionEncryptDecrypt() {
        let text = TestDataHelper.jsonImpressionSample
        let key = String(UUID().uuidString.prefix(32))
        encryptDecryptTest(originalText: text, key: key)
    }

    func testEventEncryptDecrypt() {
        let text = TestDataHelper.jsonEventSample
        let key = String(UUID().uuidString.prefix(32))
        encryptDecryptTest(originalText: text, key: key)
    }

    func testVeryLongTextEncryptDecrypt() {

        let text = TestDataHelper.veryLongText
        let key = String(UUID().uuidString.prefix(32))
        encryptDecryptTest(originalText: text, key: key)
    }

    private func encryptDecryptTest(originalText: String, key: String) {
        let encrypted = cipher.encrypt(originalText, key: key)
        let decrypted = cipher.decrypt(encrypted, key: key)

        XCTAssertNotEqual(originalText, encrypted)
        XCTAssertEqual(originalText, decrypted)
    }

    override func tearDown() {
    }
}


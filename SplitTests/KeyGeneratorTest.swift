//
//  KeyGeneratorTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11-Apr-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class KeyGeneratorTest: XCTestCase {
    private let generator = DefaultKeyGenerator()

    override func setUp() {}

    func testGenerationOk() {
        let key = generator.generateKey(size: 16)

        XCTAssertNotNil(key)
        XCTAssertEqual(16, key?.count ?? 0)
    }

    override func tearDown() {}
}

//
//  FeatureFlagsPayloadDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class FeatureFlagsPayloadDecoderTest: XCTestCase {

    let decoder: DefaultFeatureFlagsPayloadDecoder = DefaultFeatureFlagsPayloadDecoder(type: Split.self)


    func testDecodeZlib() throws {
        let featureFlag = try decoder.decode(payload: TestingData.updateSplitsNotificationZlib().definition!, compressionUtil: Zlib())

        XCTAssertEqual("mauro_java", featureFlag.name!)
        XCTAssertEqual("off", featureFlag.defaultTreatment)
        XCTAssertFalse(featureFlag.killed!)
    }

    func testDecodeGzip() throws {
        let featureFlag = try decoder.decode(payload: TestingData.updateSplitsNotificationGzip().definition!, compressionUtil: Gzip())

        XCTAssertEqual("mauro_java", featureFlag.name!)
        XCTAssertEqual("off", featureFlag.defaultTreatment)
        XCTAssertFalse(featureFlag.killed!)
    }

    override func tearDown() {
    }
}


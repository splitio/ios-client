//
//  TargetingRulesChangeDecoderTest.swift
//  SplitTests
//
//  Created on 12/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

@testable import Split
import XCTest

class TargetingRulesChangeDecoderTest: XCTestCase {
    func testDecodeTargetingRulesChange() {
        // Given
        let json = """
        {
            "ff": {
                "s": 1000,
                "t": 1001,
                "d": [
                    {
                        "name": "test_split",
                        "trafficTypeName": "user",
                        "status": "active"
                    }
                ]
            },
            "rbs": {
                "s": 500,
                "t": 501,
                "d": [
                    {
                        "name": "test_segment",
                        "trafficTypeName": "user",
                        "status": "active"
                    }
                ]
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let result = try? TargetingRulesChangeDecoder.decode(from: data)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.featureFlags.since, 1000)
        XCTAssertEqual(result?.featureFlags.till, 1001)
        XCTAssertEqual(result?.featureFlags.splits.count, 1)
        XCTAssertEqual(result?.featureFlags.splits[0].name, "test_split")

        XCTAssertEqual(result?.ruleBasedSegments.since, 500)
        XCTAssertEqual(result?.ruleBasedSegments.till, 501)
        XCTAssertEqual(result?.ruleBasedSegments.segments.count, 1)
        XCTAssertEqual(result?.ruleBasedSegments.segments[0].name, "test_segment")
    }

    func testDecodeLegacySplitChangeWithFullKeys() {
        // Given
        let json = """
        {
            "since": 1000,
            "till": 1001,
            "splits": [
                {
                    "name": "test_split",
                    "trafficTypeName": "user",
                    "status": "active"
                }
            ]
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let result = try? TargetingRulesChangeDecoder.decode(from: data)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.featureFlags.since, 1000)
        XCTAssertEqual(result?.featureFlags.till, 1001)
        XCTAssertEqual(result?.featureFlags.splits.count, 1)
        XCTAssertEqual(result?.featureFlags.splits[0].name, "test_split")

        // Verify that an empty RuleBasedSegmentChange was created
        XCTAssertEqual(result?.ruleBasedSegments.since, -1)
        XCTAssertEqual(result?.ruleBasedSegments.till, -1)
        XCTAssertEqual(result?.ruleBasedSegments.segments.count, 0)
    }

    func testDecodeInvalidJson() {
        // Given
        let json = """
        {
            "invalid": "json"
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let result = try? TargetingRulesChangeDecoder.decode(from: data)

        // Then
        XCTAssertNil(result)
    }
}

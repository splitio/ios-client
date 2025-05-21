//  Created by Martin Cardozo on 21/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

class SplitDTOTests: XCTestCase {
    
    func testPrerequisitesField() {
        // Happy case
        var data = json.data(using: .utf8)!
        var result = try? TargetingRulesChangeDecoder.decode(from: data)
        XCTAssertEqual(result?.featureFlags.splits.first?.prerequisites?.first?.n, "flag1")
        XCTAssertEqual(result?.featureFlags.splits.first?.prerequisites?.first?.ts?[1], "v1")
        
        // Empty prerequisites
        data = jsonWithEmptyPrerequisites.data(using: .utf8)!
        result = try? TargetingRulesChangeDecoder.decode(from: data)
        XCTAssertEqual(result?.featureFlags.splits.first?.prerequisites?.first?.n, nil)
        XCTAssertEqual(result?.ruleBasedSegments.segments.first?.name, "test_segment")
        
        // Errors in JSON
        data = jsonWithMalformedPrerequisites.data(using: .utf8)!
        XCTAssertThrowsError(try TargetingRulesChangeDecoder.decode(from: data))
    }
    
    let json = """
    {
        "ff": {
            "s": 1000,
            "t": 1001,
            "d": [
                {
                    "name": "test_split",
                    "trafficTypeName": "user",
                    "status": "active",
                    "prerequisites": [
                      { "n": "flag1", "ts": ["on","v1"] }, 
                      { "n": "flag2", "ts": ["off"] }
                    ],
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
    
    let jsonWithEmptyPrerequisites = """
    {
        "ff": {
            "s": 1000,
            "t": 1001,
            "d": [
                {
                    "name": "test_split",
                    "trafficTypeName": "user",
                    "status": "active",
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
    
    let jsonWithMalformedPrerequisites = """
    {
        "ff": {
            "s": 1000,
            "t": 1001,
            "d": [
                {
                    "name": "test_split",
                    "trafficTypeName": "user",
                    "status": "active",
                    "prerequisites": [
                       somes, 13, https://
                    ],
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
}

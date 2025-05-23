//  Created by Martin Cardozo on 21/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

class SplitDTOTests: XCTestCase {
    
    
    func testPrerequisitesField() {
        
        let expectedFlags = ["flag1","flag2"]
        let expectedTreatments = [["on","v1"],["off"]]
        
        // Happy case
        var data = json.data(using: .utf8)!
        var result = try? TargetingRulesChangeDecoder.decode(from: data)
        
        for i in 0..<result!.featureFlags.splits[0].prerequisites!.count {
            let prerequisite = result!.featureFlags.splits[0].prerequisites![i]
            
            XCTAssertEqual(prerequisite.n!, expectedFlags[i], "Prerequisites names should be the same")
            XCTAssertEqual(prerequisite.ts!.joined(separator: ","), expectedTreatments[i].joined(separator: ","), "Prerequisites treatments should be the same")
        }
        
        // Empty prerequisites
        data = jsonWithEmptyPrerequisites.data(using: .utf8)!
        result = try? TargetingRulesChangeDecoder.decode(from: data)
        XCTAssertEqual(result?.featureFlags.splits.first?.prerequisites?.first?.n, nil, "Prerequisites field should be empty")
        XCTAssertEqual(result?.ruleBasedSegments.segments.first?.name, "test_segment", "Rest of the response should be correct")
        
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

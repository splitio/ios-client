//  Created by Martin Cardozo on 21/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

class SplitDTOTests: XCTestCase {
    
    let expectedFlags = ["flag1","flag2"]
    let expectedTreatments = [["on","v1"],["off"]]
    
    func testPrerequisitesField() {
        
        // Happy case
        var data = correctJson
        var decoded = try? TargetingRulesChangeDecoder.decode(from: data.data(using: .utf8)!)
        
        for i in 0..<decoded!.featureFlags.splits[0].prerequisites!.count {
            let prerequisite = decoded!.featureFlags.splits[0].prerequisites![i]
            
            XCTAssertEqual(prerequisite.n!, expectedFlags[i], "Prerequisites flag names should be the same")
            XCTAssertEqual(prerequisite.ts!.joined(separator: ","), expectedTreatments[i].joined(separator: ","), "Prerequisites treatments should be the same")
        }
        
        // Empty prerequisites
        data = jsonWithEmptyPrerequisites
        decoded = try? TargetingRulesChangeDecoder.decode(from: data.data(using: .utf8)!)
        XCTAssertEqual(decoded?.featureFlags.splits.first?.prerequisites?.first?.n, nil, "Prerequisites field should be empty")
        XCTAssertEqual(decoded?.ruleBasedSegments.segments.first?.name, "test_segment", "Rest of the response should be correct")
        
        // Error in JSON
        data = jsonWithMalformedPrerequisites
        XCTAssertThrowsError(try TargetingRulesChangeDecoder.decode(from: data.data(using: .utf8)!), "Wrong JSON should throw decoding error")
    }
    
    let correctJson = """
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

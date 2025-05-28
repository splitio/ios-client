//  Created by Martin Cardozo on 26/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

class PrerequisitesMatcherTests: XCTestCase {
    
    private var storage = SplitsStorageStub()
    private var context: EvalContext?
    private var values: EvalValues!
    
    override func setUp() {
        splitsSetup()
    }
    
    func testPrerequisiteMet() {
        let prerequisites = [
            Prerequisite(flagName: "always_on", treatments: ["not-existing", "on", "other"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertTrue(SUT.evaluate(values: values, context: context), "If a prerequisite is met it should return true")
    }
    
    func testPrerequisiteMet2() {
        let prerequisites = [
            Prerequisite(flagName: "always_off", treatments: ["not-existing", "off"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertTrue(SUT.evaluate(values: values, context: context), "If a prerequisite is met it should return true")
    }
    
    func testPrerequisiteNotMet() {
        let prerequisites = [
            Prerequisite(flagName: "always_on", treatments: ["off", "v1"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertFalse(SUT.evaluate(values: values, context: context), "If just one prerequisite is not met it should return false")
    }
    
    func testPrerequisiteNotMet2() {
        let prerequisites = [
            Prerequisite(flagName: "always_off", treatments: ["on", "v1"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertFalse(SUT.evaluate(values: values, context: context), "If just one prerequisite is not met it should return false")
    }
    
    func testMultiplePrerequisites() {
        let prerequisites = [
            Prerequisite(flagName: "always_on", treatments: ["on"]),
            Prerequisite(flagName: "always_off", treatments: ["off"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertTrue(SUT.evaluate(values: values, context: context), "If all prerequisites are met it should return true")
    }
    
    func testMultiplePrerequisites2() {
        let prerequisites = [
            Prerequisite(flagName: "always_on", treatments: ["on"]),
            Prerequisite(flagName: "always_off", treatments: ["on"])
        ]
        
        let SUT = PrerequisitesMatcher(prerequisites)

        XCTAssertFalse(SUT.evaluate(values: values, context: context), "If any prerequisite is not met it should return false")
    }
    
    //MARK: Edge cases
    func testNoPrerequisites() {
        let SUT = PrerequisitesMatcher(nil)

        XCTAssertTrue(SUT.evaluate(values: values, context: context), "If there is no prerequisites, it should return true")
    }
    
    func testEmptyPrerequisites() {
        let SUT = PrerequisitesMatcher([])

        XCTAssertTrue(SUT.evaluate(values: values, context: context), "If prerequisites exists but it's just empty, it should return true")
    }
    
    func testNonExistentFeatureFlag() {
        let SUT = PrerequisitesMatcher([Prerequisite(flagName: "asldjh38", treatments: ["on"])])

        XCTAssertFalse(SUT.evaluate(values: values, context: context), "If the feature flag is non existent it should return false")
    }

}

//MARK: Testing Data
extension PrerequisitesMatcherTests {
    
    func splitsSetup() {
        
        // SPLIT 1
        let split = SplitDTO(name: "always_on", trafficType: "user", status: .active, sets: [], json: "", killed: false, impressionsDisabled: false)
        split.trafficAllocation = 100
        split.trafficAllocationSeed = 1012950810
        split.seed = -725161385
        split.defaultTreatment = "off"
        split.changeNumber = 1494364996459
        let decoder = JSONDecoder()
        let split1Condition = """
        {
            "conditionType": "ROLLOUT",
            "matcherGroup": {
                "combiner": "AND",
                "matchers": [
                    {
                        "keySelector": { "trafficType": "user", "attribute": null },
                        "matcherType": "ALL_KEYS",
                        "negate": false,
                        "userDefinedSegmentMatcherData": null,
                        "whitelistMatcherData": null,
                        "unaryNumericMatcherData": null,
                        "betweenMatcherData": null
                    }
                ]
            },
            "partitions": [
                { "treatment": "on", "size": 100 },
                { "treatment": "off", "size": 0 }
            ],
            "label": "in segment all"
        }
        """.data(using: .utf8)!
        var condition = try! decoder.decode(Condition.self, from: split1Condition)
        split.conditions = [condition]
        
        // SPLIT 2
        let split2 = SplitDTO(name: "always_off", trafficType: "user", status: .active, sets: [], json: "", killed: false, impressionsDisabled: false)
        split2.trafficAllocation = 100
        split2.trafficAllocationSeed = -331690370
        split2.seed = 403891040
        split2.defaultTreatment = "on"
        split2.changeNumber = 1494365020316
        let split2Condition = """
        {
          "conditionType": "ROLLOUT",
          "matcherGroup": {
            "combiner": "AND",
            "matchers": [
              {
                "keySelector": {
                  "trafficType": "user",
                  "attribute": null
                },
                "matcherType": "ALL_KEYS",
                "negate": false,
                "userDefinedSegmentMatcherData": null,
                "whitelistMatcherData": null,
                "unaryNumericMatcherData": null,
                "betweenMatcherData": null
              }
            ]
          },
          "partitions": [
            { "treatment": "on", "size": 0 },
            { "treatment": "off", "size": 100 }
          ],
          "label": "in segment all"
        }
        """.data(using: .utf8)!
        condition = try! decoder.decode(Condition.self, from: split2Condition)
        split2.conditions = [condition]
        
        storage.updateWithoutChecks(split: split)
        storage.updateWithoutChecks(split: split2)
        
        context = EvalContext(evaluator: DefaultEvaluator(splitsStorage: storage, mySegmentsStorage: MySegmentsStorageStub()), mySegmentsStorage: MySegmentsStorageStub(), myLargeSegmentsStorage: nil, ruleBasedSegmentsStorage: nil)
        
        values = EvalValues(matchValue: "", matchingKey: "", bucketingKey: nil)
    }
}

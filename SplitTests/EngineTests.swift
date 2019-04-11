//
//  EngineTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class EngineTests: XCTestCase {

    var splitEngine: Engine!
    let matchingKey = "test_key"
    
    override func setUp() {
        splitEngine = Engine.shared
    }

    override func tearDown() {
    }

    func testAlgoNull() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
            split?.algo = nil
            treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = nil")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testAlgoLegacy() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
        split?.algo = 1
        treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = 1 (Legacy)")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testAlgoMurmur3() {
        var treatment: [String: String]? = nil
        let split: Split? = loadSplit(splitName: "split_sample_feature6")
        do {
            split?.algo = 2
            treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(treatment, "Treatment should not be nil when algo = 2 (Murmur3)")
        XCTAssertTrue(treatment?[Engine.EVALUATION_RESULT_TREATMENT] == "t4_6", "Expected treatment 'On', obtained '\(treatment?[Engine.EVALUATION_RESULT_TREATMENT] ?? "null")'")
    }
    
    func testsTrafficAllocation50DefaultRule50() {
        
        let keys = [
        "81179b66-00e9-46a8-8fbd-8a4e653eca81",
        "694d9f9f-f196-48d9-a20a-8b6bfe485ffe",
        "95a6c7dd-e680-4d4c-9492-fd4f8f6cbcd7",
        "aa9055eb-710c-4817-93bc-6906db5f4934",
        "001c0296-3942-4ccf-b2e7-fc26dd625599",
        "8771ab59-daf5-40de-a368-6bb06f2a876f",
        "c9b346a3-9841-4553-af86-8bcb90459f02",
        "a0175f00-bf9f-415d-ad56-d5d161c8b659",
        "4888b362-f4ae-4b4f-a65d-2920dd660476",
        "f0584475-a1da-4222-9718-5692bc3fe968"
        ]
        var treatment: [String: String]? = nil
        var results = [String: Int]()
        let split: Split? = loadSplit(splitName: "split_traffic_alloc_50_default_rule_50")
        for matchingKey in keys {
            do {
                treatment = try splitEngine.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
                if let result = treatment, result[Engine.EVALUATION_RESULT_LABEL] == "default rule" {
                    let t = result[Engine.EVALUATION_RESULT_TREATMENT]!
                    results[t] = (results[t] ?? 0) + 1
                }
            } catch {
            }
        }
        XCTAssertTrue(results["on"] ?? 0 > 0)
        XCTAssertTrue(results["off"] ?? 0 > 0)
    }

    func loadSplit(splitName: String) -> Split? {
        if let splitContent = FileHelper.readDataFromFile(sourceClass: self, name: splitName, type: "json") {
            do {
                return try JSON(splitContent.data(using: .utf8)).decode(Split.self)
            } catch {
                print("Decoding split for algo null test failed")
            }
        } else {
            print("Error loading file \(splitName)")
        }
        return nil
    }
    
}

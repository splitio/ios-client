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
    
    var evaluator: Engine!
    let matchingKey = "test_key"
    var split: Split?
    
    override func setUp() {
        evaluator = Engine.shared
        split = loadSplit(splitName: "split_sample_feature6")
    }
    
    override func tearDown() {
    }
    
    func testAlgoNull() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = nil
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
            } catch {
            }
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = nil")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configurations)
    }
    
    func testAlgoLegacy() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = 1
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
            } catch {
            }
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 1 (Legacy)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configurations)
    }
    
    func testAlgoMurmur3() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = 2
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
            } catch {
            }
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 2 (Murmur3)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configurations)
    }
    
    func testEqualsToSetNoConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atributo2": ["salamin"]]
                split.algo = 2
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t1_6", result?.treatment)
        XCTAssertNil(result?.configurations)
    }
    
    func testMatchesStringNoConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atributo1": "mila"]
                split.algo = 2
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t3_6", result?.treatment)
        XCTAssertNil(result?.configurations)
    }
    
    func testEqualsToSetConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atribute": ["papapa"]]
                split.algo = 2
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t2_6", result?.treatment)
        XCTAssertNotNil(result?.configurations)
    }
    
    func testDefaultTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.trafficAllocation = 0
                split.algo = 2
                result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, split: split, attributes: nil)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result?.treatment)
        XCTAssertNotNil(result?.configurations)
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

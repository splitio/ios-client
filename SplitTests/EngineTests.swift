//
//  EngineTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

@testable import Split
import XCTest

class EngineTests: XCTestCase {
    var evaluator: Engine!
    let matchingKey = "test_key"
    var split: Split?

    override func setUp() {
        evaluator = Engine.shared
        split = loadSplit(splitName: "split_sample_feature6")
    }

    override func tearDown() {}

    func testAlgoNull() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = nil
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {}
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = nil")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }

    func testAlgoLegacy() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = 1
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {}
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 1 (Legacy)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }

    func testAlgoMurmur3() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {}
        }
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 2 (Murmur3)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }

    func testsTrafficAllocation50DefaultRule50() {
        let theKey = "8771ab59-daf5-40de-a368-6bb06f2a876f"
        var treatmentOn: EvaluationResult? = nil
        var treatmentOff: EvaluationResult? = nil
        var treatmentOutOfSplit: EvaluationResult? = nil
        var treatmentSeedDefaultOff: EvaluationResult? = nil
        var treatmentSeedOutOfSplit: EvaluationResult? = nil
        let split: Split? = loadSplit(splitName: "split_traffic_alloc_50_default_rule_50")

        do {
            // Changing key
            treatmentOn = try evaluator.getTreatment(
                matchingKey: theKey,
                bucketingKey: nil,
                split: split!,
                attributes: nil)
            treatmentOff = try evaluator.getTreatment(
                matchingKey: "aa9055eb-710c-4817-93bc-6906db5f4934",
                bucketingKey: nil,
                split: split!,
                attributes: nil)
            treatmentOutOfSplit = try evaluator.getTreatment(
                matchingKey: "5a2e15a7-d1a3-481f-bf40-4aecb72c9a40",
                bucketingKey: nil,
                split: split!,
                attributes: nil)

            // Changing seed
            // Seed default off
            split?.seed = 997637287
            treatmentSeedDefaultOff = try evaluator.getTreatment(
                matchingKey: theKey,
                bucketingKey: nil,
                split: split!,
                attributes: nil)

            // Traffic allocation out
            split?.trafficAllocationSeed = 1444036110
            treatmentSeedOutOfSplit = try evaluator.getTreatment(
                matchingKey: theKey,
                bucketingKey: nil,
                split: split!,
                attributes: nil)

        } catch {
            print(error)
        }
        XCTAssertEqual("on", treatmentOn?.treatment)
        XCTAssertEqual("default rule", treatmentOn?.label)

        XCTAssertEqual("off", treatmentOff?.treatment)
        XCTAssertEqual("default rule", treatmentOff?.label)

        XCTAssertEqual("off", treatmentOutOfSplit?.treatment)
        XCTAssertEqual("not in split", treatmentOutOfSplit?.label)

        XCTAssertEqual("off", treatmentSeedOutOfSplit?.treatment)
        XCTAssertEqual("not in split", treatmentSeedOutOfSplit?.label)

        XCTAssertEqual("off", treatmentSeedDefaultOff?.treatment)
        XCTAssertEqual("default rule", treatmentSeedDefaultOff?.label)
    }

    func testEqualsToSetNoConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atributo2": ["salamin"]]
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t1_6", result?.treatment)
        XCTAssertNil(result?.configuration)
    }

    func testMatchesStringNoConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atributo1": "mila"]
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t3_6", result?.treatment)
        XCTAssertNil(result?.configuration)
    }

    func testEqualsToSetConfigTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                let attributes = ["atribute": ["papapa"]]
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: attributes)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t2_6", result?.treatment)
        XCTAssertNotNil(result?.configuration)
    }

    func testDefaultTreatment() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.trafficAllocation = 0
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result?.treatment)
        XCTAssertNotNil(result?.configuration)
        XCTAssertEqual("not in split", result?.label)
    }

    func testDefaultRule() {
        var result: EvaluationResult!
        if let split = split {
            do {
                split.trafficAllocation = 100
                split.algo = 2
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t4_6", result?.treatment)
        XCTAssertNotNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
    }

    func testInSegmentsRule() {
        var result: EvaluationResult!
        if let split = loadSplit(splitName: "in_segment_condition_split") {
            do {
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t3", result?.treatment)
        XCTAssertNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
    }

    func testMissingDefaultRule() {
        var result: EvaluationResult!
        if let split = loadSplit(splitName: "in_segment_condition_split") {
            let defaultRuleIndex = split.conditions!.count - 1
            split.conditions?.remove(at: defaultRuleIndex)
            do {
                result = try evaluator.getTreatment(
                    matchingKey: matchingKey,
                    bucketingKey: nil,
                    split: split,
                    attributes: nil)
            } catch {
                print(error)
            }
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t1", result?.treatment)
        XCTAssertNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
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

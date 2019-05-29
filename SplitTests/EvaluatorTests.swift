//
//  EvaluatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 27/03/2018.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class EvaluatorTests: XCTestCase {
    
    var evaluator: Evaluator!
    let matchingKey = "test_key"
    
    override func setUp() {
        if evaluator == nil {
            let mySegments = ["s1", "s2", "test_copy"]
            let splitFetcher: SplitFetcher = SplitFetcherStub(splits: loadSplitsFile())
            let mySegmentsFetcher: MySegmentsFetcher = MySegmentsFetcherStub(mySegments: mySegments)
            let client: InternalSplitClient = InternalSplitClientStub(splitFetcher: splitFetcher, mySegmentsFetcher: mySegmentsFetcher)
            evaluator = DefaultEvaluator(splitClient: client)
        }
    }
    
    override func tearDown() {
    }
    
    func testWhitelisted() {
        var result: EvaluationResult!
        let matchingKey = "nico_test"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("on", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testWhitelistedOff() {
        var result: EvaluationResult!
        let matchingKey = "bla"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testDefaultTreatmentFacundo() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("in segment all", result.label)
        
    }
    
    func testInSegmentTestKey() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "a_new_split_2"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted segment", result.label)
        
    }
    
    func testKilledSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "Test"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNotNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.KILLED, result.label)
    }
    
    func testNotInSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "split_not_available_to_test_right_now"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.CONTROL, result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.SPLIT_NOT_FOUND, result.label)
    }
    
    func testBrokenSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "broken_split"
        do {
            result = try evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.CONTROL, result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.EXCEPTION, result.label)
    }
    
    func testAlgoNull() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.algo = nil
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
        XCTAssertNotNil(result, "Treatment should not be nil when algo = nil")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }
    
    func testAlgoLegacy() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 1 (Legacy)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }
    
    func testAlgoMurmur3() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
        XCTAssertNotNil(result, "Treatment should not be nil when algo = 2 (Murmur3)")
        XCTAssertTrue(result.treatment == "t4_6", "Expected treatment 'On', obtained '\(result.treatment)'")
        XCTAssertNotNil(result.configuration)
    }
    
    func testsTrafficAllocation50DefaultRule50() {
        
        let theKey = "8771ab59-daf5-40de-a368-6bb06f2a876f"
        var treatmentOn: EvaluationResult?  = nil
        var treatmentOff: EvaluationResult?  = nil
        var treatmentOutOfSplit: EvaluationResult?  = nil
        var treatmentSeedDefaultOff: EvaluationResult?  = nil
        var treatmentSeedOutOfSplit: EvaluationResult?  = nil
        
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_traffic_alloc_50_default_rule_50") else {
            XCTAssertTrue(false)
            return
        }
        let splitName = split.name!
        split.algo = 2
        evaluator = customEvaluator(split: split)
        
        do {
            // Changing key
            treatmentOn = try evaluator.getTreatment(matchingKey: theKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
            treatmentOff = try evaluator.getTreatment(matchingKey: "aa9055eb-710c-4817-93bc-6906db5f4934", bucketingKey: nil, splitName: splitName, attributes: nil)
            treatmentOutOfSplit = try evaluator.getTreatment(matchingKey: "5a2e15a7-d1a3-481f-bf40-4aecb72c9a40", bucketingKey: nil, splitName: splitName, attributes: nil)
            
            // Changing seed
            // Seed default off
            split.seed = 997637287
            treatmentSeedDefaultOff = try evaluator.getTreatment(matchingKey: theKey, bucketingKey: nil, splitName: splitName, attributes: nil)
            
            // Traffic allocation out
            split.trafficAllocationSeed = 1444036110
            treatmentSeedOutOfSplit = try evaluator.getTreatment(matchingKey: theKey, bucketingKey: nil, splitName: splitName, attributes: nil)
            
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
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        let attributes = ["atributo2": ["salamin"]]
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)

        XCTAssertNotNil(result)
        XCTAssertEqual("t1_6", result?.treatment)
        XCTAssertNil(result?.configuration)
    }
    
    func testMatchesStringNoConfigTreatment() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        let attributes = ["atributo1": "mila"]
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("t3_6", result?.treatment)
        XCTAssertNil(result?.configuration)
    }
    
    func testEqualsToSetConfigTreatment() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        let attributes = ["atribute": ["papapa"]]
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("t2_6", result?.treatment)
        XCTAssertNotNil(result?.configuration)
    }
    
    func testDefaultTreatment() {
        
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.trafficAllocation = 0
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result?.treatment)
        XCTAssertNotNil(result?.configuration)
        XCTAssertEqual("not in split", result?.label)
    }
    
    func testInSegmentsRule1() {
        var result: EvaluationResult!
        let evaluator = customEvaluator(splitFile: "segment_conta_condition")
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: "failing_test", attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("t3", result?.treatment)
        XCTAssertNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
    }
    
    func testDefaultRule() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.trafficAllocation = 100
        split.algo = 2
        evaluator = customEvaluator(split: split)
        result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual("t4_6", result?.treatment)
        XCTAssertNotNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
    }
    
    func testMissingDefaultRule() {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        if let split = loadSplit(splitName: "in_segment_condition_split") {
            let defaultRuleIndex  = split.conditions!.count - 1
            split.conditions?.remove(at: defaultRuleIndex)
            evaluator = customEvaluator(split: split)
            result = try? evaluator.getTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("t1", result?.treatment)
        XCTAssertNil(result?.configuration)
        XCTAssertEqual("default rule", result?.label)
    }
    
    func testAllocation1Percent() {
        var treatment = ""
        var result: EvaluationResult!
        let evaluator = customEvaluator(splitFile: "split_traffic_allocation_1") as! DefaultEvaluator
        evaluator.splitter = SplitterAllocationFake()
        
        result = try? evaluator.getTreatment(matchingKey: "thekey", bucketingKey: nil, splitName: "split", attributes: nil)

        treatment = result!.treatment
        XCTAssertEqual(treatment, "on", "Result should be 'on'")
    }
    
    func loadSplitsFile() -> [Split] {
        return loadSplitFile(name: "splitchanges_1")
    }
    
    func loadSplitFile(name fileName: String) -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self),
            let splits = change.splits {
            return splits
        }
        return [Split]()
    }
    
    func customEvaluator(splitFile fileName: String) -> Evaluator {
        let mySegments: [String] = []
        var splits: [Split] = []
        if let split = loadSplit(splitName: fileName) {
            splits.append(split)
        }
        let splitFetcher: SplitFetcher = SplitFetcherStub(splits: splits)
        let mySegmentsFetcher: MySegmentsFetcher = MySegmentsFetcherStub(mySegments: mySegments)
        let client: InternalSplitClient = InternalSplitClientStub(splitFetcher: splitFetcher, mySegmentsFetcher: mySegmentsFetcher)
        evaluator = DefaultEvaluator(splitClient: client)
        return evaluator
    }
    
    func customEvaluator(split: Split) -> Evaluator {
        let mySegments: [String] = []
        let splitFetcher: SplitFetcher = SplitFetcherStub(splits: [split])
        let mySegmentsFetcher: MySegmentsFetcher = MySegmentsFetcherStub(mySegments: mySegments)
        let client: InternalSplitClient = InternalSplitClientStub(splitFetcher: splitFetcher, mySegmentsFetcher: mySegmentsFetcher)
        evaluator = DefaultEvaluator(splitClient: client)
        return evaluator
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

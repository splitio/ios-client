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
    var client: InternalSplitClient!
    var mySegmentsStorage: MySegmentsStorageStub!
    var myLargeSegmentsStorage: MySegmentsStorageStub!

    override func setUp() {
        if evaluator == nil {
            let change = SegmentChange(segments: ["s1", "s2", "test_copy"])

            let splits = loadSplitsFile()
            let splitsStorage = SplitsStorageStub()
            _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits,
                                                                       archivedSplits: [],
                                                                       changeNumber: 100,
                                                                       updateTimestamp: 100))
            mySegmentsStorage = MySegmentsStorageStub()
            mySegmentsStorage.set(change, forKey: matchingKey)
            myLargeSegmentsStorage = MySegmentsStorageStub()
            client = InternalSplitClientStub(splitsStorage:splitsStorage,
                                             mySegmentsStorage: mySegmentsStorage,
                                             myLargeSegmentsStorage: myLargeSegmentsStorage)
            evaluator = DefaultEvaluator(splitsStorage: splitsStorage,
                                         mySegmentsStorage: mySegmentsStorage,
                                         myLargeSegmentsStorage: EmptyMySegmentsStorage())
        }
    }
    
    func testWhitelisted() {
        var result: EvaluationResult!
        let matchingKey = "nico_test"
        let splitName = "FACUNDO_TEST"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("on", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testWhitelistedOff() {
        var result: EvaluationResult!
        let matchingKey = "bla"
        let splitName = "FACUNDO_TEST"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testDefaultTreatmentFacundo() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "FACUNDO_TEST"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("in segment all", result.label)
        
    }
    
    func testInSegmentTestKey() {
        var result: EvaluationResult!
        let splitName = "a_new_split_2"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual("whitelisted segment", result.label)
        
    }
    
    func testKilledSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "OldTest"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNotNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.killed, result.label)
    }
    
    func testPassingPrerequisites() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "FACUNDO_TEST"
        
        (evaluator as! DefaultEvaluator).prerequisitesMatcher = PrerequisitesMatcherMock(shouldPass: true)
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.configuration)
        XCTAssertEqual("off", result.treatment)
    }
    
    func testNotPassingPrerequisites() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "FACUNDO_TEST"
        
        (evaluator as! DefaultEvaluator).prerequisitesMatcher = PrerequisitesMatcherMock(shouldPass: false)
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(ImpressionsConstants.prerequisitesNotMet, result.label)
    }
    
    func testNotInSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "split_not_available_to_test_right_now"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.control, result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.splitNotFound, result.label)
    }
    
    func testBrokenSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "broken_split"
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: splitName, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.control, result.treatment)
        XCTAssertNil(result.configuration)
        XCTAssertEqual(ImpressionsConstants.exception, result.label)
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
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
            treatmentOn = try evaluator.evalTreatment(matchingKey: theKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
            treatmentOff = try evaluator.evalTreatment(matchingKey: "aa9055eb-710c-4817-93bc-6906db5f4934", bucketingKey: nil, splitName: splitName, attributes: nil)
            treatmentOutOfSplit = try evaluator.evalTreatment(matchingKey: "5a2e15a7-d1a3-481f-bf40-4aecb72c9a40", bucketingKey: nil, splitName: splitName, attributes: nil)
            
            // Changing seed
            // Seed default off
            split.seed = 997637287
            treatmentSeedDefaultOff = try evaluator.evalTreatment(matchingKey: theKey, bucketingKey: nil, splitName: splitName, attributes: nil)
            
            // Traffic allocation out
            split.trafficAllocationSeed = 1444036110
            treatmentSeedOutOfSplit = try evaluator.evalTreatment(matchingKey: theKey, bucketingKey: nil, splitName: splitName, attributes: nil)
            
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)

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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)
        
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: attributes)
        
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result?.treatment)
        XCTAssertNotNil(result?.configuration)
        XCTAssertEqual("not in split", result?.label)
    }
    
    func testInSegmentsRule1() {
        var result: EvaluationResult!
        let evaluator = customEvaluator(splitFile: "segment_conta_condition")
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: "failing_test", attributes: nil)
        
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
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
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
            result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)
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
        
        result = try? evaluator.evalTreatment(matchingKey: "thekey", bucketingKey: nil, splitName: "split", attributes: nil)

        treatment = result!.treatment
        XCTAssertEqual(treatment, "on", "Result should be 'on'")
    }

    func testInLargeSegmentWhitelist() {
        inLargeSegmentWhiteListTest(key: matchingKey)
    }

    func testNotInLargeSegmentWhitelist() {
        inLargeSegmentWhiteListTest(key: "the_bad_key", treatment: "off")
    }

    func testimpressionsDisabledNil() {
        withImpressionsDisabled(nil)
    }

    func testImpressionsDisabledTrue() {
        withImpressionsDisabled(true)
    }

    func testImpressionsDisabledFalse() {
        withImpressionsDisabled(false)
    }

    private func withImpressionsDisabled(_ disabled: Bool?) {
        var result: EvaluationResult!
        var evaluator: Evaluator!
        guard let split = loadSplit(splitName: "split_sample_feature6") else {
            XCTAssertTrue(false)
            return
        }
        split.algo = 2
        if (disabled != nil) {
            split.impressionsDisabled = disabled
        }
        evaluator = customEvaluator(split: split)
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: split.name!, attributes: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual("t4_6", result?.treatment)
        XCTAssertEqual(disabled ?? false, result!.impressionsDisabled)
    }

    func inLargeSegmentWhiteListTest(key: String, treatment: String = "on") {

        var treatment = ""
        var result: EvaluationResult!
        let evaluator = customEvaluator(splitFile: "in_large_segment_whitelist_split", largeSegments: ["segment1"]) as! DefaultEvaluator
        evaluator.splitter = SplitterAllocationFake()
        
        result = try? evaluator.evalTreatment(matchingKey: matchingKey, bucketingKey: nil, splitName: "ls_split", attributes: nil)

        treatment = result!.treatment
        XCTAssertEqual(treatment, treatment, "Result should be 'on'")
    }

    func loadSplitsFile() -> [Split] {
        return loadSplitFile(name: "splitchanges_1")
    }

    func loadSplitFile(name fileName: String) -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change.featureFlags.splits
        }
        return [Split]()
    }
    
    func customEvaluator(splitFile fileName: String, largeSegments: [String]? = nil) -> Evaluator {
        let mySegments: [String] = []
        let split = loadSplit(splitName: fileName)!
        let splitsStorage = SplitsStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split],
                                                               archivedSplits: [],
                                                               changeNumber: 100, 
                                                               updateTimestamp: 100))
        let mySegmentsStorage = MySegmentsStorageStub()
        mySegmentsStorage.set(SegmentChange(segments: mySegments), forKey: matchingKey)

        let myLargeSegmentsStorage = MySegmentsStorageStub()
        myLargeSegmentsStorage.set(SegmentChange(segments: largeSegments ?? []), forKey: matchingKey)

        client = InternalSplitClientStub(splitsStorage:splitsStorage, 
                                         mySegmentsStorage: mySegmentsStorage,
                                         myLargeSegmentsStorage: myLargeSegmentsStorage)
        evaluator = DefaultEvaluator(splitsStorage: splitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     myLargeSegmentsStorage: myLargeSegmentsStorage)
        return evaluator
    }
    
    func customEvaluator(split: Split, largeSegments: [String]? = nil) -> Evaluator {
        let splitsStorage = SplitsStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split], 
                                                               archivedSplits: [],
                                                               changeNumber: 100,
                                                               updateTimestamp: 100))
        let mySegmentsStorage = MySegmentsStorageStub()
        mySegmentsStorage.set(SegmentChange(segments:[]), forKey: matchingKey)

        let myLargeSegmentsStorage = MySegmentsStorageStub()
        myLargeSegmentsStorage.set(SegmentChange(segments:largeSegments ?? []), forKey: matchingKey)

        client = InternalSplitClientStub(splitsStorage:splitsStorage,
                                         mySegmentsStorage: mySegmentsStorage,
                                         myLargeSegmentsStorage: myLargeSegmentsStorage)
        evaluator = DefaultEvaluator(splitsStorage: splitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     myLargeSegmentsStorage: myLargeSegmentsStorage)
        return evaluator
    }
    
    func loadSplit(splitName: String) -> Split? {
        if let splitContent = FileHelper.readDataFromFile(sourceClass: self, name: splitName, type: "json") {
            do {
                let split = try JSON(splitContent.data(using: .utf8)).decode(Split.self)
                return split
            } catch {
                print("Decoding split for algo null test failed")
            }
        } else {
            print("Error loading file \(splitName)")
        }
        return nil
    }
    
}

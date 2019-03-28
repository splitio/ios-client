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
            evaluator = Evaluator.shared
            let mySegments = ["s1", "s2", "test_copy"]
            let splitFetcher: SplitFetcher = SplitFetcherStub(splits: loadSplitsFile())
            let mySegmentsFetcher: MySegmentsFetcher = MySegmentsFetcherStub(mySegments: mySegments)
            let client: InternalSplitClient = InternalSplitClientStub(splitFetcher: splitFetcher, mySegmentsFetcher: mySegmentsFetcher)
            evaluator.splitClient = client
        }
    }
    
    override func tearDown() {
    }
    
    func testWhitelisted() {
        var result: EvaluationResult!
        let matchingKey = "nico_test"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("on", result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testWhitelistedOff() {
        var result: EvaluationResult!
        let matchingKey = "bla"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual("whitelisted", result.label)
    }
    
    func testDefaultTreatmentFacundo() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "FACUNDO_TEST"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual("in segment all", result.label)
        
    }
    
    func testInSegmentTestKey() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "a_new_split_2"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual("whitelisted segment", result.label)
        
    }
    
    func testKilledSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "Test"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual("off", result.treatment)
        XCTAssertNotNil(result.configurations)
        XCTAssertEqual(ImpressionsConstants.KILLED, result.label)
    }
    
    func testNotInSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "split_not_available_to_test_right_now"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.CONTROL, result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual(ImpressionsConstants.SPLIT_NOT_FOUND, result.label)
    }
    
    func testBrokenSplit() {
        var result: EvaluationResult!
        let matchingKey = "anyKey"
        let splitName = "broken_split"
        do {
            result = try evaluator.evalTreatment(key: matchingKey, bucketingKey: nil, split: splitName, attributes: nil)
        } catch {
        }
        XCTAssertNotNil(result)
        XCTAssertEqual(SplitConstants.CONTROL, result.treatment)
        XCTAssertNil(result.configurations)
        XCTAssertEqual(ImpressionsConstants.EXCEPTION, result.label)
    }
    
    func loadSplitsFile() -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self),
            let splits = change.splits {
            return splits
        }
        return [Split]()
    }
}

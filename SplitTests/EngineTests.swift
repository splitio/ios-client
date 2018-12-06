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

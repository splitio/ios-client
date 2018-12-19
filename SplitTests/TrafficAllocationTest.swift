//
//  TrafficAllocation1PercentTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/12/2018.
//  Copyright © 2018 Split. All rights reserved.
//
/// This tests is intended to verify the correct engine behavior when
/// traffic allocation in split is set to 1 percent

import XCTest
@testable import Split

class TrafficAllocationTest: XCTestCase {

    var splitHelper: SplitHelper!
    var splitEngine: Engine!
    
    override func setUp() {
        splitHelper = SplitHelper()
        splitEngine = Engine(splitter: SplitterAllocationFake())
    }

    override func tearDown() {
    }

    func testAllocation1Percent() {
        var treatment = ""
        let split = splitHelper.loadSplitFromFile(name: "split_traffic_allocation_1")!
        let result = try? splitEngine.getTreatment(matchingKey: "aaaaaaklmnbv", bucketingKey: nil, split: split, attributes: nil)
        treatment = result![Engine.EVALUATION_RESULT_TREATMENT]!
        XCTAssertEqual(treatment, "on", "Result should be 'on'")
    }

}

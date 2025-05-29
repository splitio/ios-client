//
//  FlagSetValidatorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 22/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

@testable import Split
import XCTest

class FlagSetValidatorTests: XCTestCase {
    var validator: DefaultFlagSetsValidator!
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        super.setUp()
        telemetryProducer = TelemetryStorageStub()
        validator = DefaultFlagSetsValidator(telemetryProducer: telemetryProducer)
    }

    func testValidateOnEvaluationWithFilteredValues() {
        let values = ["test1", "TEST2", " test3 "]
        let setsInFilter = ["test1", "test2"]
        let result = validator.validateOnEvaluation(values, calledFrom: "TestMethod", setsInFilter: setsInFilter)
        XCTAssertEqual(result.sorted(), ["test1", "test2"])
        XCTAssertEqual(3, telemetryProducer.getTotalFlagSets())
        XCTAssertEqual(0, telemetryProducer.getInvalidFlagSets())
    }

    func testCleanAndValidateValues() {
        let values = [
            "Test1",
            "TEST2 ",
            " test2 ",
            "test_value@",
            "TEST3",
            "test4_",
            "_test1",
            "test-1",
            "1test",
            "-test1",
            "HoLA",
            "hola",
            "@@@@",
            "*test",
            "test*test",
            "test()",
            "(test)",
            "1|test",
            "test\\",
        ]

        let result = validator.cleanAndValidateValues(values, calledFrom: "TestMethod")
        XCTAssertEqual(result.sorted(), ["1test", "hola", "test1", "test2", "test3", "test4_"])
        XCTAssertEqual(19, telemetryProducer.getTotalFlagSets())
        XCTAssertEqual(13, telemetryProducer.getInvalidFlagSets())
    }
}

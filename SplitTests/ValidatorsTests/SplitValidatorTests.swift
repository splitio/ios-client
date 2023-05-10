//
//  SplitNameValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitValidatorTests: XCTestCase {
    
    var validator: SplitValidator!
    
    override func setUp() {
        let splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [createSplit(name: "split1")],
                                                               archivedSplits: [],
                                                               changeNumber: 100, updateTimestamp: 100))
        validator = DefaultSplitValidator(splitsStorage: splitsStorage)
    }
    
    override func tearDown() {
    }
    
    func testValidName() {
        XCTAssertNil(validator.validate(name: "name1"))
    }
    
    func testNullName() {
        let errorInfo = validator.validate(name: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed a null split name, split name must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyName() {
        let errorInfo = validator.validate(name: "")
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed an empty split name, split name must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testLeadingSpacesName() {
        let errorInfo = validator.validate(name: " split")
        XCTAssertNotNil(errorInfo)
        XCTAssertFalse(errorInfo?.isError ?? true)
        XCTAssertEqual("split name ' split' has extra whitespace, trimming", errorInfo?.warnings.values.map ({$0})[0])
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.splitNameShouldBeTrimmed) ?? false)
    }
    
    func testTrailingSpacesName() {
        let errorInfo = validator.validate(name: "split ")
        XCTAssertNotNil(errorInfo)
        XCTAssertFalse(errorInfo?.isError ?? true)
        XCTAssertEqual("split name 'split ' has extra whitespace, trimming", errorInfo?.warnings.values.map ({$0})[0])
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.splitNameShouldBeTrimmed) ?? false)
    }
    
    func testExistingSplit() {
        let errorInfo = validator.validateSplit(name: "split1")
        
        XCTAssertNil(errorInfo)
    }
    
    func testNoExistingSplit() {
        let errorInfo = validator.validateSplit(name: "split2")
        
        XCTAssertFalse(errorInfo?.isError ?? true)
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.nonExistingSplit) ?? false)
        XCTAssertEqual("you passed 'split2' that does not exist in this environment, please double check what Splits exist in the Split user interface.", errorInfo?.warnings[.nonExistingSplit])
    }
    
    func createSplit(name: String) -> Split {
        let split = Split()
        split.name = name
        return split
    }
    
    
}

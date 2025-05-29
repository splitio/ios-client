//
//  SemverTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

final class SemverTest: XCTestCase {
    func testBetween() {
        if let data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: "between_semver") {
            let lines = CsvHelper.csv(data: data)

            lines.forEach { line in
                let version1 = Semver.build(version: line[0])!
                let version2 = Semver.build(version: line[1])!
                let version3 = Semver.build(version: line[2])!
                let expectedResult = Bool(line[3])!

                let result: Bool = version2.compare(to: version1) >= 0 && version2.compare(to: version3) <= 0

                if expectedResult != result {
                    XCTFail()
                }
            }
        }
    }

    func testEqualTo() {
        if let data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: "equal_to_semver") {
            let lines = CsvHelper.csv(data: data)

            lines.forEach { line in
                let version1 = Semver.build(version: line[0])!
                let version2 = Semver.build(version: line[1])!
                let expectedResult = Bool(line[2])!

                let result: Bool = version1 == version2

                if expectedResult != result {
                    XCTFail()
                }
            }
        }
    }

    func testGreaterThanOrEqualTo() {
        if let data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: "valid_semantic_versions") {
            let lines = CsvHelper.csv(data: data)

            lines.forEach { line in
                let version1 = Semver.build(version: line[0])!
                let version2 = Semver.build(version: line[1])!

                XCTAssertEqual(0, version1.compare(to: version1))
                XCTAssertEqual(0, version2.compare(to: version2))
            }
        }
    }

    func testLessThanOrEqualTo() {
        if let data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: "valid_semantic_versions") {
            let lines = CsvHelper.csv(data: data)

            lines.forEach { line in
                let version1 = Semver.build(version: line[0])!
                let version2 = Semver.build(version: line[1])!
                XCTAssertFalse(version1.compare(to: version2) <= 0)
                XCTAssertTrue(version2.compare(to: version1) <= 0)
                XCTAssertEqual(0, version1.compare(to: version1))
                XCTAssertEqual(0, version2.compare(to: version2))
            }
        }
    }

    func testInvalidFormats() {
        if let data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: "invalid_semantic_versions") {
            let lines = CsvHelper.csv(data: data)

            lines.forEach { line in
                XCTAssertNil(Semver.build(version: line[0]))
            }
        }
    }
}

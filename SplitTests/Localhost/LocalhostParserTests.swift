//
//  LocalhostParserTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 30/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class LocalhostParserTests: XCTestCase {
    let parser: LocalhostSplitsParser = SpaceDelimitedLocalhostSplitsParser()
    override func setUp() {}

    override func tearDown() {}

    func testPerfectFile() {
        let splits = parser.parseContent(openFile(number: 1))!
        for i in 1 ... 3 {
            XCTAssertEqual("t\(i)", splits["split\(i)"]?.conditions?[0].partitions?[0].treatment)
        }
    }

    func testSpacedLinesFile() {
        let splits = parser.parseContent(openFile(number: 2))!
        for i in 1 ... 5 {
            XCTAssertEqual("t\(i)", splits["split\(i)"]?.conditions?[0].partitions?[0].treatment)
        }
    }

    func testIntercomentedLinesFile() {
        let splits = parser.parseContent(openFile(number: 3))!
        for i in 1 ... 9 {
            XCTAssertEqual("t\(i)", splits["split\(i)"]?.conditions?[0].partitions?[0].treatment)
        }
    }

    private func openFile(number: Int) -> String {
        let fileName = "localhost_\(number)"
        let content = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "splits")
        return content ?? ""
    }
}

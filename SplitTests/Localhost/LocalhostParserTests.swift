//
//  LocalhostParserTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 30/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class LocalhostParserTests: XCTestCase {
    
    let parser: LocalhostSplitsParser = SpaceDelimitedLocalhostSplitsParser()
    override func setUp() {
    }

    override func tearDown() {
    }

    func testFile1() {
        let splits = parser.parseContent(openFile(number: 1))
        
    }
    
    
    private func openFile(number: Int) -> String {
        let fileName = "localhost_\(number)"
        let content = FileHelper.readDataFromFile(sourceClass: self, name:fileName, type: "splits")
        return content ?? ""
    }

}

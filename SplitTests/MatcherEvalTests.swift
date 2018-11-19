//
//  HashingTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 12/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split



class MatcherEvalTests: XCTestCase {
    
    struct Test: Decodable {
        var description: String
        var matcherType: String
        var values: [Int64]
        var results: [Int]
        var matcher: Matcher
        
        func result(for index: Int) -> Bool {
            return results[index] == 1 ? true : false
        }
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testEval() {
        let fileContent = FileHelper.readDataFromFile(sourceClass: self, name: "matchers", type: "json")
        XCTAssertNotNil(fileContent, "Matcher file should not be null")
        var matcherTests: [Test]? = nil
        do {
            matcherTests = try Json.encodeFrom(json: fileContent!, to: [Test].self)
        } catch {
            print("Error loading tests file: \(error)")
        }
        XCTAssertNotNil(matcherTests, "File tests not loaded")
        
        if let tests = matcherTests {
            for test in tests {
                let values: [Int64] = test.values
                let matcher = (try? test.matcher.getMatcher())!
                for (index, value) in values.enumerated() {
                    let evalResult = matcher.evaluate(matchValue: value, bucketingKey: nil, attributes: nil)
                    let expectedResult = test.result(for: index)
                    XCTAssertTrue(evalResult == expectedResult, "Failed: \(test.description) Value: \(value) -> Expected: \(expectedResult), Result: \(evalResult)")
                }
            }
        }
    }
}

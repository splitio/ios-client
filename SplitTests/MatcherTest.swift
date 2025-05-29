//
//  MatcherTest.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class MatcherTests: XCTestCase {
    func testMatcher() {
        let matcher = try? JSON.decodeFrom(json: "{}", to: Matcher.self)
        let expectedVal = EvaluatorError.matcherNotFound
        do {
            _ = try matcher!.getMatcher()
        } catch EvaluatorError.matcherNotFound {
            debugPrint("MATCHER NOT FOUND")
            XCTAssertEqual(expectedVal, EvaluatorError.matcherNotFound, "Matcher should be equal to NOT_FOUND value")
            return
        } catch {
            debugPrint("Exception")
        }
    }
}

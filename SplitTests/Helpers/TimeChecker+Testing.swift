//
//  TimeChecker+Testing.swift
//  SplitTests
//

import Foundation
@testable import Split

extension TimeChecker {
    static func forTesting(factoryId: Int = 0) -> TimeChecker {
        return TimeChecker(factoryId: factoryId, startTime: Date.nowMillis())
    }
}

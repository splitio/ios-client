//
//  DatesTests.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 2/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

/***
 * Not sure what is this test about
 * ToDo: Ask about it
 *
 **/

import Foundation
import XCTest

@testable import Split

class DatesTest: XCTestCase {
    override func setUp() {}

    override func tearDown() {}

    func testDates() {
        let timestamp1 = 1461280509
        let timestamp2 = 1461196800

        let d1 = normalizeDate(timestamp: TimeInterval(timestamp1))
        let d2 = normalizeDate(timestamp: TimeInterval(timestamp2))
        XCTAssertEqual(d1, d2, "Normalized dates should be equal")
    }

    // MARK: Helpers

    func normalizeDate(timestamp: TimeInterval) -> Date {
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current

        var dateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0

        return calendar.date(from: dateComponents)!
    }

    func testSecondsToDays() {
        let seconds: Int64 = 86400
        let days = Date.secondsToDays(seconds: seconds)
        XCTAssertEqual(days, 1, "1 day should be the result")

        let seconds2: Int64 = 172800
        let days2 = Date.secondsToDays(seconds: seconds2)
        XCTAssertEqual(days2, 2, "2 days should be the result")
    }
}

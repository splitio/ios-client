//
//  ImpressionsCounterTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 22/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class ImpressionsCounterTest: XCTestCase {
    typealias CountMap = [ImpressionsCounter.Key: Int]

    override func setUp() {}

    func testTruncateTime() {
        let time1 = Date
            .truncateTimeframe(millis: makeTimestamp(hour: 10, minute: 53, second: 12).unixTimestampInMiliseconds())
        let timeframe1 = makeTimestamp(hour: 10, minute: 0, second: 0).unixTimestampInMiliseconds()

        let time2 = Date
            .truncateTimeframe(millis: makeTimestamp(hour: 10, minute: 0, second: 0).unixTimestampInMiliseconds())
        let timeframe2 = makeTimestamp(hour: 10, minute: 0, second: 0).unixTimestampInMiliseconds()

        let time3 = Date
            .truncateTimeframe(millis: makeTimestamp(hour: 10, minute: 53, second: 0).unixTimestampInMiliseconds())
        let timeframe3 = makeTimestamp(hour: 10, minute: 0, second: 0).unixTimestampInMiliseconds()

        let time4 = Date
            .truncateTimeframe(millis: makeTimestamp(hour: 10, minute: 0, second: 12).unixTimestampInMiliseconds())
        let timeframe4 = makeTimestamp(hour: 10, minute: 0, second: 0).unixTimestampInMiliseconds()

        let time2019 = Date.truncateTimeframe(millis: makeTimestamp(
            year: 2019,
            month: 6,
            hour: 1,
            minute: 18,
            second: 12).unixTimestampInMiliseconds())
        let timeframe2019 = makeTimestamp(year: 2019, month: 6, hour: 1, minute: 0, second: 0)
            .unixTimestampInMiliseconds()

        let time2021 = Date.truncateTimeframe(millis: makeTimestamp(
            year: 2021,
            month: 12,
            hour: 23,
            minute: 59,
            second: 50).unixTimestampInMiliseconds())
        let timeframe2021 = makeTimestamp(year: 2021, month: 12, hour: 23, minute: 0, second: 0)
            .unixTimestampInMiliseconds()

        let time1970 = Date
            .truncateTimeframe(
                millis: makeTimestamp(year: 1970, hour: 1, minute: 18, second: 12)
                    .unixTimestampInMiliseconds())
        let timeframe1970 = makeTimestamp(year: 1970, hour: 1, minute: 0, second: 0).unixTimestampInMiliseconds()

        XCTAssertEqual(timeframe1, time1)
        XCTAssertEqual(timeframe2, time2)
        XCTAssertEqual(timeframe3, time3)
        XCTAssertEqual(timeframe4, time4)
        XCTAssertEqual(timeframe2019, time2019)
        XCTAssertEqual(timeframe2021, time2021)
        XCTAssertEqual(timeframe1970, time1970)
    }

    func testBasicUsage() {
        let counter = ImpressionsCounter()
        let timestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 10, minute: 10, second: 12)
            .unixTimestampInMiliseconds()
        let truncatedTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 10, minute: 0, second: 0)
            .unixTimestampInMiliseconds()
        counter.inc(featureName: "feature1", timeframe: timestamp, amount: 1)
        counter.inc(featureName: "feature1", timeframe: timestamp + 1, amount: 1)
        counter.inc(featureName: "feature1", timeframe: timestamp + 2, amount: 1)
        counter.inc(featureName: "feature2", timeframe: timestamp + 3, amount: 2)
        counter.inc(featureName: "feature2", timeframe: timestamp + 4, amount: 2)

        let counted: CountMap = counter.popAll().reduce(CountMap()) { dic, count -> CountMap in
            var newDic = dic
            newDic[CountMap.Key(featureName: count.feature, timeframe: count.timeframe)] = count.count
            return newDic
        }

        let nextHourTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 11, minute: 10, second: 12)
            .unixTimestampInMiliseconds()
        let truncatedNextHourTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 11, minute: 0, second: 0)
            .unixTimestampInMiliseconds()
        counter.inc(featureName: "feature1", timeframe: timestamp, amount: 1)
        counter.inc(featureName: "feature1", timeframe: timestamp + 1, amount: 1)
        counter.inc(featureName: "feature1", timeframe: timestamp + 2, amount: 1)
        counter.inc(featureName: "feature2", timeframe: timestamp + 3, amount: 2)
        counter.inc(featureName: "feature2", timeframe: timestamp + 4, amount: 2)
        counter.inc(featureName: "feature1", timeframe: nextHourTimestamp, amount: 1)
        counter.inc(featureName: "feature1", timeframe: nextHourTimestamp + 1, amount: 1)
        counter.inc(featureName: "feature1", timeframe: nextHourTimestamp + 2, amount: 1)
        counter.inc(featureName: "feature2", timeframe: nextHourTimestamp + 3, amount: 2)
        counter.inc(featureName: "feature2", timeframe: nextHourTimestamp + 4, amount: 2)

        let counted1: CountMap = counter.popAll().reduce(CountMap()) { dic, count -> CountMap in
            var newDic = dic
            newDic[CountMap.Key(featureName: count.feature, timeframe: count.timeframe)] = count.count
            return newDic
        }

        XCTAssertEqual(counted.count, 2)
        XCTAssertEqual(counted[ImpressionsCounter.Key(featureName: "feature1", timeframe: truncatedTimestamp)], 3)
        XCTAssertEqual(counted[ImpressionsCounter.Key(featureName: "feature2", timeframe: truncatedTimestamp)], 4)
        XCTAssertEqual(counter.popAll().count, 0)

        XCTAssertEqual(counted1.count, 4)
        XCTAssertEqual(counted1[ImpressionsCounter.Key(featureName: "feature1", timeframe: truncatedTimestamp)], 3)
        XCTAssertEqual(counted1[ImpressionsCounter.Key(featureName: "feature2", timeframe: truncatedTimestamp)], 4)
        XCTAssertEqual(
            counted1[ImpressionsCounter.Key(featureName: "feature1", timeframe: truncatedNextHourTimestamp)],
            3)
        XCTAssertEqual(
            counted1[ImpressionsCounter.Key(featureName: "feature2", timeframe: truncatedNextHourTimestamp)],
            4)
        XCTAssertEqual(counter.popAll().count, 0)
    }

    func testConcurrency() throws {
        let queue = DispatchQueue(label: "q1", attributes: .concurrent)
        let iterations = 20000
        let counter = ImpressionsCounter()
        let timestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 10, minute: 10, second: 12)
            .unixTimestampInMiliseconds()
        let truncatedTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 10, minute: 0, second: 0)
            .unixTimestampInMiliseconds()

        let nextHourTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 11, minute: 10, second: 12)
            .unixTimestampInMiliseconds()
        let truncatedNextHourTimestamp = makeTimestamp(year: 2020, month: 9, day: 2, hour: 11, minute: 0, second: 0)
            .unixTimestampInMiliseconds()

        let exp1 = XCTestExpectation()
        let exp2 = XCTestExpectation()

        queue.async {
            for _ in 0 ..< iterations {
                counter.inc(featureName: "feature1", timeframe: timestamp, amount: 1)
                counter.inc(featureName: "feature2", timeframe: timestamp, amount: 1)
                counter.inc(featureName: "feature1", timeframe: nextHourTimestamp, amount: 2)
                counter.inc(featureName: "feature2", timeframe: nextHourTimestamp, amount: 2)
            }
            exp1.fulfill()
        }

        queue.async {
            for _ in 0 ..< iterations {
                counter.inc(featureName: "feature1", timeframe: timestamp, amount: 2)
                counter.inc(featureName: "feature2", timeframe: timestamp, amount: 2)
                counter.inc(featureName: "feature1", timeframe: nextHourTimestamp, amount: 1)
                counter.inc(featureName: "feature2", timeframe: nextHourTimestamp, amount: 1)
            }
            exp2.fulfill()
        }

        wait(for: [exp1, exp2], timeout: 10)

        let counted: CountMap = counter.popAll().reduce(CountMap()) { dic, count -> CountMap in
            var newDic = dic
            newDic[CountMap.Key(featureName: count.feature, timeframe: count.timeframe)] = count.count
            return newDic
        }

        let expectedValue = iterations * 3

        XCTAssertEqual(counted.count, 4)
        XCTAssertEqual(
            counted[ImpressionsCounter.Key(featureName: "feature1", timeframe: truncatedTimestamp)],
            expectedValue)
        XCTAssertEqual(
            counted[ImpressionsCounter.Key(featureName: "feature2", timeframe: truncatedTimestamp)],
            expectedValue)
        XCTAssertEqual(
            counted[ImpressionsCounter.Key(featureName: "feature1", timeframe: truncatedNextHourTimestamp)],
            expectedValue)
        XCTAssertEqual(
            counted[ImpressionsCounter.Key(featureName: "feature2", timeframe: truncatedNextHourTimestamp)],
            expectedValue)
        XCTAssertEqual(counter.popAll().count, 0)
    }

    override func tearDown() {}

    private func makeTimestamp(
        year: Int = 2020,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 1,
        minute: Int = 1,
        second: Int = 0) -> Date {
        let calendar = Calendar.current
        let date = DateComponents(
            calendar: calendar,
            timeZone: TimeZone.current,
            era: nil,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: nil,
            weekday: nil,
            weekdayOrdinal: nil,
            quarter: nil,
            weekOfMonth: nil,
            weekOfYear: nil,
            yearForWeekOfYear: nil).date
        return date!
    }
}

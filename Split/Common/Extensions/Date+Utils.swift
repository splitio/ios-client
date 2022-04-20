//
//  Date+Range.swift
//  Split
//
//  Created by Natalia  Stele on 26/11/2017.
//

import Foundation

private let kTimeIntervalMs: Int64 = 3600 * 1000

extension Date {

    public func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self) == self.compare(date2)
    }

    public static func dateFromInt(number: Int64) -> Date {

        let time = TimeInterval(number)

        return Date(timeIntervalSince1970: time)

    }

}

extension Date {
    func unixTimestamp() -> Int64 {
        return Int64(self.timeIntervalSince1970)
    }

    func unixTimestampInMiliseconds() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }

    func unixTimestampInMicroseconds() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000000)
    }

    static func truncateTimeframe(millis: Int64) -> Int64 {
        return Int64(millis - (millis % kTimeIntervalMs))
    }
}

extension Date {
    static func now() -> Int64 {
        return Date().unixTimestamp()
    }
}

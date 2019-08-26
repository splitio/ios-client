//
//  DateTime.swift
//  Split
//
//  Created by Sebastian Arrubia on 2/2/18.
//

import Foundation

public class DateTime: NSObject {
    static func zeroOutTime(timestamp: TimeInterval) -> Date {

        let date = Date(timeIntervalSince1970: Double(Int64(timestamp)))
        let calendar = Calendar.current

        var dateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0

        return calendar.date(from: dateComponents)!
    }

    static func zeroOutSeconds(timestamp: TimeInterval) -> Date {
        let date = Date(timeIntervalSince1970: Double(Int64(timestamp)))
        let calendar = Calendar.current

        var dateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        dateComponents.second = 0

        return calendar.date(from: dateComponents)!
    }
}

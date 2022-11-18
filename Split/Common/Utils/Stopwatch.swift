//
//  Stopwatch.swift
//  Split
//
//  Created by Javier Avrudsky on 16-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

// Warning: Do not use instance class methods
// in multithread environment
// Multithread code is avoided on purpose to avoid
// delays while time measuring
// call start only once and then interval

class Stopwatch {
    enum TimeUnit {
        case milliseconds
        case microseconds
    }
    private var startTime: Int64 = 0
    private var startTimeUnit: TimeUnit = .microseconds

    func start(unit: TimeUnit = .microseconds) {
        if startTime == 0 {
            startTime = Stopwatch.now(unit: unit)
        }
    }

    func interval() -> Int64 {
        return Stopwatch.interval(from: startTime, unit: startTimeUnit)
    }

    static func now(unit: TimeUnit = .microseconds) -> Int64 {
        return Date().unixTimestampInMiliseconds()
    }

    static func interval(from startTime: Int64, unit: TimeUnit = .microseconds) -> Int64 {
        return Stopwatch.now() - startTime
    }
}

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
    private var startTime: Int64 = 0

    func start() {
        if startTime == 0 {
            startTime = Stopwatch.now()
        }
    }

    func interval() -> Int64 {
        return Stopwatch.interval(from: startTime)
    }

    static func now() -> Int64 {
        return Date().unixTimestampInMiliseconds()
    }

    static func interval(from startTime: Int64) -> Int64 {
        return Stopwatch.now() - startTime
    }
}

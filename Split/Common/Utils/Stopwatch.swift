//
//  Stopwatch.swift
//  Split
//
//  Created by Javier Avrudsky on 16-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class Stopwatch {
    private var startTime: Int64 = 0

    func start() {
        startTime = Date().unixTimestampInMiliseconds()
    }

    func interval() -> Int64 {
        return Date().unixTimestampInMiliseconds() - startTime
    }

    func reset() {
        startTime = 0
    }

    static func now() -> Int64 {
        return Date().unixTimestampInMiliseconds()
    }

    static func interval(from startTime: Int64) -> Int64 {
        return Date().unixTimestampInMiliseconds() - startTime
    }
}

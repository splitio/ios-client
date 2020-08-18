//
//  ReconnectBackoffCounter.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol ReconnectBackoffCounter {
    func getNextRetryTime() -> Int
    func resetCounter()
}

class DefaultReconnectBackoffCounter {
    private static let kMaxTimeLimitInSecs = 1800 // 30 minutes (30 * 60)
    private static let kRetryExponentialBase = 2
    private let backoffBase: Int
    private var attemptCount: AtomicInt

    init(backoffBase: Int) {
        self.backoffBase = backoffBase
        self.attemptCount = AtomicInt(0)
    }

    func getNextRetryTime() -> Int {

        let base = Decimal(backoffBase * Self.kRetryExponentialBase)
        let decimalResult = pow(base, attemptCount.getAndAdd(1))

        var retryTime = Self.kMaxTimeLimitInSecs
        if !decimalResult.isNaN, decimalResult < Decimal(Self.kMaxTimeLimitInSecs) {
            retryTime = (decimalResult as NSDecimalNumber).intValue
        }
        return retryTime
    }

    func resetCounter() {
        attemptCount .mutate { $0 = 0 }
    }
}

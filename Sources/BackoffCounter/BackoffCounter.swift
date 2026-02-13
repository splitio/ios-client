//  BackoffCounter
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.

import Foundation

public protocol BackoffCounter {
    func getNextRetryTime() -> Double
    func resetCounter()
}

public class DefaultBackoffCounter: BackoffCounter, @unchecked Sendable {
    private var maxTimeLimitInSecs: Double = 1800.0 // 30 minutes (30 * 60)
    private static let kRetryExponentialBase = 2
    private let backoffBase: Int
    private var attemptCount: Int = 0
    private let lock = NSLock()

    public init(backoffBase: Int, maxTimeLimit: Int? = nil) {
        self.backoffBase = backoffBase
        if let max = maxTimeLimit {
            maxTimeLimitInSecs = Double(max)
        }
    }

    @discardableResult
    public func getNextRetryTime() -> Double {
        lock.lock()
        let currentAttempt = attemptCount
        attemptCount += 1
        lock.unlock()

        let base = Decimal(backoffBase * Self.kRetryExponentialBase)
        let decimalResult = pow(base, currentAttempt)

        var retryTime = maxTimeLimitInSecs
        if !decimalResult.isNaN, decimalResult < Decimal(maxTimeLimitInSecs) {
            retryTime = (decimalResult as NSDecimalNumber).doubleValue
        }
        return retryTime
    }

    public func resetCounter() {
        lock.lock()
        attemptCount = 0
        lock.unlock()
    }
}

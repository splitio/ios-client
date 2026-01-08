//
//  ReconnectBackoffCounterStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class ReconnectBackoffCounterStub: ReconnectBackoffCounter, @unchecked Sendable {
    var resetCounterCalled = false
    var retryCallCount = 0
    var nextRetryTime: Double = 1

    func getNextRetryTime() -> Double {
        retryCallCount+=1
        return nextRetryTime
    }

    func resetCounter() {
        resetCounterCalled = true
    }
}

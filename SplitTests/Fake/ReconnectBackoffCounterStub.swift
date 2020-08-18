//
//  ReconnectBackoffCounterStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class ReconnectBackoffCounterStub: ReconnectBackoffCounter {
    var resetCounterCalled = false
    var nextRetryTime: Int = 0

    func getNextRetryTime() -> Int {
        return nextRetryTime
    }

    func resetCounter() {
        resetCounterCalled = true
    }
}

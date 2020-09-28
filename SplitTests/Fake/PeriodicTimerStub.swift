//
//  PeriodicTimerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split

class PeriodicTimerStub: PeriodicTimer {

    var timerHandler: (() -> Void)?

    func trigger() {
    }

    func cancel() {
    }

    func handler( _ handler: @escaping () -> Void) {
        timerHandler = handler
    }
}

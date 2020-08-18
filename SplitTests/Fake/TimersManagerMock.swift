//
//  TimersManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class TimersManagerMock: TimersManager {
    private var timersAdded = Set<TimerName>()
    private var timersCancelled = Set<TimerName>()

    func add(timer: TimerName, delayInSeconds: Int) {
        timersAdded.insert(timer)
    }

    func cancel(timer: TimerName) {
        timersCancelled.insert(timer)
    }

    func triggerHandler(handler: (TimerName) -> Void) {
    }

    func timerIsAdded(timer: TimerName) -> Bool {
        return timersAdded.contains(timer)
    }

    func timerIsCancelled(timer: TimerName) -> Bool {
        return timersCancelled.contains(timer)
    }
}


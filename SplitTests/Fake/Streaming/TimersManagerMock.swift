//
//  TimersManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class TimersManagerMock: TimersManager {
    var triggerHandler: TimerHandler?

    private var timersAdded = Set<TimerName>()
    private var timersCancelled = Set<TimerName>()
    private var expectations = [TimerName: XCTestExpectation]()

    func add(timer: TimerName, delayInSeconds: Int) {
        timersAdded.insert(timer)
        if let exp = expectations[timer] {
            exp.fulfill()
        }
    }

    func cancel(timer: TimerName) {
        timersCancelled.insert(timer)
    }

    func timerIsAdded(timer: TimerName) -> Bool {
        return timersAdded.contains(timer)
    }

    func timerIsCancelled(timer: TimerName) -> Bool {
        return timersCancelled.contains(timer)
    }

    func addExpectationFor(timer: TimerName, expectation: XCTestExpectation) {
        expectations[timer] = expectation
    }

    func reset(timer: TimerName? = nil) {
        if let timer = timer {
            timersAdded.remove(timer)
            timersCancelled.remove(timer)
        } else {
            timersAdded.removeAll()
            timersCancelled.removeAll()
        }
    }
}


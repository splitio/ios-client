//
//  TimersManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 21/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class TimersManagerTest: XCTestCase {
    var timersManager: TimersManager!

    override func setUp() {
        timersManager = DefaultTimersManager()
    }

    func testAddTimer() {
        let exp = XCTestExpectation(description: "exp")
        var triggered = false
        let task = DefaultTask(delay: 1) {
            exp.fulfill()
            triggered = true
        }
        timersManager.add(timer: .refreshAuthToken, task: task)

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(triggered)
    }

    func testAddAndCancelTimer() {
        // Two timers are created
        // the timer that should be triggered first is cancelled
        // so, only longer timer should be fired
        let exp = XCTestExpectation(description: "exp")
        var triggered = false
        var cancelled = true

        let task1 = DefaultTask(delay: 1) {
            cancelled = false
        }

        let task2 = DefaultTask(delay: 3) {
            exp.fulfill()
            triggered = true
        }

        timersManager.add(timer: .refreshAuthToken, task: task1)
        timersManager.add(timer: .appHostBgDisconnect, task: task2)
        timersManager.cancel(timer: .refreshAuthToken)
        wait(for: [exp], timeout: 10)

        XCTAssertTrue(triggered)
        XCTAssertTrue(cancelled)
    }

    override func tearDown() {}
}

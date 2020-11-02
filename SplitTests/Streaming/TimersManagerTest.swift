//
//  TimersManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 21/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class TimersManagerTest: XCTestCase {

    var timersManager: TimersManager!

    override func setUp() {
        timersManager = DefaultTimersManager()
    }

    func testAddTimer() {
        let exp = XCTestExpectation(description: "exp")
        var triggered = false
        timersManager.triggerHandler = { timer in
            if timer == .refreshAuthToken {
                exp.fulfill()
                triggered = true
            }
        }
        timersManager.add(timer: .refreshAuthToken, delayInSeconds: 1)

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
        timersManager.triggerHandler = { timer in
            switch timer {
            case .refreshAuthToken:
                cancelled = false
            default:
                exp.fulfill()
                triggered = true

            }
        }
        timersManager.add(timer: .refreshAuthToken, delayInSeconds: 1)
        timersManager.add(timer: .appHostBgDisconnect, delayInSeconds: 3)
        timersManager.cancel(timer: .refreshAuthToken)
        wait(for: [exp], timeout: 3)

        XCTAssertTrue(triggered)
        XCTAssertTrue(cancelled)
    }

    override func tearDown() {

    }
}

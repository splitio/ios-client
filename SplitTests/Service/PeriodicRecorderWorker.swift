//
//  PeriodicRecorderWorker.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import XCTest

class PeriodicRecorderWorkerTests: XCTestCase {
    var recorderWorker: RecorderWorkerStub!
    var periodicRecorderWorker: PeriodicRecorderWorker!

    override func setUp() {
        recorderWorker = RecorderWorkerStub()
    }

    func testTimerFire() {
        let timer = PeriodicTimerStub()
        periodicRecorderWorker = DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: recorderWorker)

        periodicRecorderWorker.start()

        for _ in 0 ..< 5 {
            timer.timerHandler?()
        }

        sleep(1)
        XCTAssertEqual(5, recorderWorker.flushCallCount)
    }

    func testStop() {
        let timer = PeriodicTimerStub()
        periodicRecorderWorker = DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: recorderWorker)

        periodicRecorderWorker.start()
        periodicRecorderWorker.stop()

        XCTAssertEqual(1, timer.stopCallCount)
        XCTAssertEqual(0, timer.destroyCallCount)
    }

    func testDestroy() {
        let timer = PeriodicTimerStub()
        periodicRecorderWorker = DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: recorderWorker)

        periodicRecorderWorker.start()
        periodicRecorderWorker.destroy()

        XCTAssertEqual(1, timer.destroyCallCount)
    }
}

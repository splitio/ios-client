//  PeriodicRecorderWorkerTest
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.

import XCTest
@testable import PeriodicRecorderWorker

final class RecorderWorkerStub: RecorderWorker, @unchecked Sendable {
    var flushCallCount = 0
    
    func flush() {
        flushCallCount += 1
    }
}

final class PeriodicTimerStub: PeriodicTimer, @unchecked Sendable {
    var timerHandler: (() -> Void)?
    var triggerCallCount = 0
    var stopCallCount = 0
    var destroyCallCount = 0
    
    func trigger() {
        triggerCallCount += 1
    }
    
    func stop() {
        stopCallCount += 1
    }
    
    func destroy() {
        destroyCallCount += 1
    }
    
    func handler(_ handler: @escaping () -> Void) {
        timerHandler = handler
    }
}

// MARK: - Tests

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

        for _ in 0..<5 {
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

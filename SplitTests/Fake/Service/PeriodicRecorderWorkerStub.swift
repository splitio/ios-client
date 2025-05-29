//
//  PeriodicRecorderWorkerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/01/2021.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PeriodicRecorderWorkerStub: PeriodicRecorderWorker {
    var startCalled = false
    var resumeCalled = false
    var pauseCalled = false
    var stopCalled = false
    var destroyCalled = false

    func start() {
        startCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func destroy() {
        destroyCalled = true
    }
}

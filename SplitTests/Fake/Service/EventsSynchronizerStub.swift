//
//  EventsSynchronizerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 30-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class EventsSynchronizerStub: EventsSynchronizer {
    var startCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var pushCalled = false
    var flushCalled = false
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

    func flush() {
        flushCalled = true
    }

    func push(_ event: EventDTO) {
        pushCalled = true
    }

    func destroy() {
        destroyCalled = true
    }
}

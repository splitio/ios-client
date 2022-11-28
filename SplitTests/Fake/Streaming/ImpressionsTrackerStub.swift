//
//  ImpressionsTrackerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsTrackerStub: ImpressionsTracker {
    var isTrackingEnabled: Bool = true
    var startCalled = false
    func start() {
        startCalled = true
    }

    var pauseCalled = false
    func pause() {
        pauseCalled = true
    }

    var resumeCalled = false
    func resume() {
        resumeCalled = true
    }

    var stopCalled = false
    func stop() {
        stopCalled = true
    }

    var flushCalled = false
    func flush() {
        flushCalled = true
    }

    var pushCalled = false
    func push(_ impression: KeyImpression) {
        pushCalled = true
    }

    var destroyCalled = false
    func destroy() {
        destroyCalled = true
    }
}

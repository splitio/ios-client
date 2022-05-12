//
//  SyncManagerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 21-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class SyncManagerStub: SyncManager {

    var startCalled = false
    func start() {
        startCalled = true
    }

    var resetStreamingCalled = false
    func resetStreaming() {
        resetStreamingCalled = true
    }

    var pauseCalled = false
    func pause() {
        pauseCalled = true
    }

    var resumeCalled = false
    func resume() {
        resetStreamingCalled = true
    }

    var stopCalled = false
    func stop() {
        stopCalled = true
    }


}

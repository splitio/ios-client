//
//  SyncWorkerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split

class RetryableSyncWorkerStub: RetryableSyncWorker {
    var completion: SyncCompletion?

    var startCalled = false
    var stopCalled = false

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }
}

class PeriodicSyncWorkerStub: PeriodicSyncWorker {

    var startCalled = false
    var stopCalled = false
    var destroyCalled = false

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func destroy() {
        destroyCalled = true
    }
}

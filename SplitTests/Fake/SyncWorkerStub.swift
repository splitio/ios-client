//
//  SyncWorkerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class RetryableSyncWorkerStub: RetryableSyncWorker, @unchecked Sendable {

    var completion: SyncCompletion?
    var errorHandler: ErrorHandler?

    var startCalled = false
    var stopCalled = false

    var errorToThrowOnStart: HttpError?

    func start() {
        startCalled = true
        if let error = errorToThrowOnStart {
            errorHandler?(error)
        }
    }

    func stop() {
        stopCalled = true
    }
}

class PeriodicSyncWorkerStub: PeriodicSyncWorker, @unchecked Sendable {

    var startCalled = false
    var stopCalled = false
    var destroyCalled = false
    var pauseCalled = false
    var resumeCalled = false

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func destroy() {
        destroyCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }
}

class RetryableMySegmentsSyncWorkerStub: RetryableSyncWorker, @unchecked Sendable {

    var errorHandler: ErrorHandler?

    init(userKey: String? = nil, avoidCache: Bool? = nil) {
        self.userKey = userKey
        self.avoidCache = avoidCache
    }

    var userKey: String?
    var avoidCache: Bool?
    var completion: SyncCompletion?
    var startCalled = false
    var stopCalled = false
    var startExp: XCTestExpectation?

    func start() {
        startCalled = true
        startExp?.fulfill()
    }

    func stop() {
        stopCalled = true
    }
}

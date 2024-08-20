//
//  UpdateWorkerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitsUpdateWorkerMock: SplitsUpdateWorker {
    var processCalled = false
    var throwException = false
    override func process(notification: SplitsUpdateNotification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class MySegmentsUpdateWorkerMock: MySegmentsUpdateWorker {
    var processCalled = false
    var throwException = false
    override func process(notification: MySegmentsUpdateNotification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class MySegmentsUpdateV2WorkerMock: MySegmentsUpdateV2Worker {
    var processCalled = false
    var throwException = false
    override func process(notification: MySegmentsUpdateV2Notification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class MyLargeSegmentsUpdateWorkerMock: MyLargeSegmentsUpdateWorker {
    var processCalled = false
    var throwException = false
    override func process(notification: MyLargeSegmentsUpdateNotification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class SplitKillWorkerMock: SplitKillWorker {
    var processCalled = false
    var throwException = false
    override func process(notification: SplitKillNotification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class SegmentsUpdateWorkerHelperMock: SegmentsUpdateWorkerHelper {
    var processCalled = false
    func process(_ info: SegmentsProcessInfo) {
        processCalled = true
    }
}

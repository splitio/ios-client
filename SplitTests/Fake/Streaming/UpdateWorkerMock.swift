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
    override func process(notification: TargetingRuleUpdateNotification) throws {
        if throwException {
            throw GenericError.unknown(message: "")
        }
        processCalled = true
    }
}

class SegmentsUpdateWorkerMock: SegmentsUpdateWorker {
    var processCalled = false
    var throwException = false
    override func process(notification: MembershipsUpdateNotification) throws {
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

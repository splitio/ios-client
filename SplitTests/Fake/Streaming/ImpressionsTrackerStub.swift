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
    var stopImpressionsCalled = false
    var stopUniqueKeysCalled = false
    func stop(_ service: RecordingService) {
        switch service {
        case .all:
            stopCalled = true
        case .impressions:
            stopImpressionsCalled = true
        case .uniqueKeys:
            stopUniqueKeysCalled = true
        }
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

    func enableTracking(_ enable: Bool) {
        isTrackingEnabled = enable
    }

    var isPersistenceEnabled = false
    func enablePersistence(_ enable: Bool) {
        isPersistenceEnabled = enable
    }
}

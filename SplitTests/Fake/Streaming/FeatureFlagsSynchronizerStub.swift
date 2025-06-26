//
//  FeatureFlagsSynchronizerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//
import Foundation
@testable import Split

class FeatureFlagsSynchronizerStub: FeatureFlagsSynchronizer {
   var loadCalled = false
    func load() {
        loadCalled = true
    }

    var synchronizeCalled = false
    func synchronize() {
        synchronizeCalled = true
    }

    var synchronizeNumberCalled = false
    func synchronize(changeNumber: Int64?, rbsChangeNumber: Int64?) {
        synchronizeNumberCalled = true
    }

    var startPeriodicSyncCalled = false
    func startPeriodicSync() {
        startPeriodicSyncCalled = true
    }

    var stopPeriodicSyncCalled = false
    func stopPeriodicSync() {
        stopPeriodicSyncCalled = true
    }

    var notifyKilledCalled = false
    var killedFlag = ""
    func notifyKilled(flag: String) {
        killedFlag = flag
        notifyKilledCalled = true
    }

    var notifyUpdatedCalled = false
    var updatedFlags: [String] = []
    func notifyUpdated(flags: [String]) {
        updatedFlags = flags
        notifyUpdatedCalled = true
    }
    
    var notifyUpdatedSegmentsCalled = false
    var updatedSegments: [String] = []
    func notifyUpdated(ruleBasedSegments: [String]) {
        updatedSegments = ruleBasedSegments
        notifyUpdatedSegmentsCalled = true
    }

    var pauseCalled = false
    func pause() {
        pauseCalled = true
    }

    var resumeCalled = false
    func resume() {
        resumeCalled = true
    }

    var destroyCalled = false
    func destroy() {
        destroyCalled = true
    }
}

//
//  FeatureFlagsSynchronizerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//
import Foundation
@testable import Split

class FeatureFlagsSynchronizerStub: FeatureFlagsSynchronizer, @unchecked Sendable {
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
    func notifyKilled() {
        notifyKilledCalled = true
    }

    var notifyUpdatedCalled: [String] = []
    func notifyUpdated(flagsList: [String]) {
        notifyUpdatedCalled = flagsList
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

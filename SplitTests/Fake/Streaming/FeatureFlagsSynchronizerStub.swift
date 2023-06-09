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
    var loadAndSynchronizeCalled = false
    func loadAndSynchronize() {
        loadAndSynchronizeCalled = true
    }

    var synchronizeCalled = false
    func synchronize() {
        synchronizeCalled = true
    }

    var synchronizeNumberCalled = false
    func synchronize(changeNumber: Int64) {
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
}

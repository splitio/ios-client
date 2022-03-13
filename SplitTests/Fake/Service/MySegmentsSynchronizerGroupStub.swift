//
//  MySegmentsSynchronizerGroupStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsSynchronizerGroupStub: MySegmentsSynchronizerGroup {

    var synchronizers = [String: MySegmentsSynchronizer]()
    var loadFromCacheCalled = false
    var startPeriodicSyncCalled = false
    var syncCalled = false
    var syncAllCalled = false
    var forceSyncCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var stopPeriodicSyncCalled = false
    var stopCalled = false

    var syncKey: String = ""
    var loadFromCacheKey: String = ""

    func append(_ synchronizer: MySegmentsSynchronizer, forKey key: String) {
        synchronizers[key] = synchronizer
    }

    func remove(forKey key: String) {
        synchronizers.removeValue(forKey: key)
    }

    func loadFromCache(forKey key: String) {
        loadFromCacheKey = key
        loadFromCacheCalled = true
    }

    func startPeriodicSync() {
        startPeriodicSyncCalled = true
    }

    func sync(forKey key: String) {
        syncKey = key
        syncCalled = true
    }

    func syncAll() {
        syncAllCalled = true
    }

    func forceSync(forKey: String) {
        forceSyncCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func stopPeriodicSync() {
        stopPeriodicSyncCalled = true
    }

    func stop() {
        stopCalled = true
    }
}

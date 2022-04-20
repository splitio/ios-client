//
//  MySegmentsSynchronizerGroupStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class ByKeyFacadeStub: ByKeyFacade {

    var components = [String: ByKeyComponentGroup]()
    var loadMySegmentsFromCacheCalled = false
    var startPeriodicSyncCalled = false
    var syncMySegmentsCalled = false
    var syncAllCalled = false
    var forceMySegmentsSyncCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var stopPeriodicSyncCalled = false
    var stopCalled = false

    var syncKey: String = ""
    var loadMySegmentsFromCacheKey: String = ""

    var loadAttributesFromCacheCalled = false
    var loadAttributesFromCacheKey: String = ""

    func append(_ group: ByKeyComponentGroup, forKey key: String) {
        components[key] = group
    }

    func remove(forKey key: String) {
        components.removeValue(forKey: key)
    }

    func loadMySegmentsFromCache(forKey key: String) {
        loadMySegmentsFromCacheKey = key
        loadMySegmentsFromCacheCalled = true
    }

    func loadAttributesFromCache(forKey key: String) {
        loadAttributesFromCacheKey = key
        loadAttributesFromCacheCalled = true
    }

    func syncMySegments(forKey key: String) {
        syncMySegmentsCalled = true
    }

    func forceMySegmentsSync(forKey: String) {
        forceMySegmentsSyncCalled = true
    }

    func startPeriodicSync() {
        startPeriodicSyncCalled = true
    }

    func sync(forKey key: String) {
        syncKey = key
        syncMySegmentsCalled = true
    }

    func syncAll() {
        syncAllCalled = true
    }

    func forceSync(forKey: String) {
        forceMySegmentsSyncCalled = true
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

    var notifyMySegmentsUpdatedCalled = false
    func notifyMySegmentsUpdated(forKey key: String) {
        notifyMySegmentsUpdatedCalled = true
    }
}

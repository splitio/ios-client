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
    var loadMySegmentsFromCacheCalled = [String: Bool]()
    var startPeriodicSyncCalled = false
    var syncMySegmentsCalled = [String: Bool]()
    var syncAllCalled = false
    var forceMySegmentsSyncCalled = [String: Bool]()
    var pauseCalled = false
    var resumeCalled = false
    var stopPeriodicSyncCalled = false
    var destroyCalled = false

    var loadAttributesFromCacheCalled = [String: Bool]()

    var keys: Set<String> {
        return Set(components.keys.map {$0 })
    }

    func append(_ group: ByKeyComponentGroup, forKey key: String) {
        components[key] = group
    }

    func remove(forKey key: String) {
        components.removeValue(forKey: key)
    }

    func loadMySegmentsFromCache(forKey key: String) {
        loadMySegmentsFromCacheCalled[key] = true
    }

    func loadAttributesFromCache(forKey key: String) {
        loadAttributesFromCacheCalled[key] = true
    }

    func syncMySegments(forKey key: String) {
        syncMySegmentsCalled[key] = true
    }

    func forceMySegmentsSync(forKey key: String) {
        forceMySegmentsSyncCalled[key] = true
    }

    func startPeriodicSync() {
        startPeriodicSyncCalled = true
    }

    func syncAll() {
        syncAllCalled = true
    }

    var startSyncForKeyCalled = [String: Bool]()
    func startSync(forKey key: String) {
        startSyncForKeyCalled[key] = true
    }

    func forceSync(forKey key: String) {
        forceMySegmentsSyncCalled[key] = true
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
        destroyCalled = true
    }

    var notifyMySegmentsUpdatedCalled = false
    func notifyMySegmentsUpdated(forKey key: String) {
        notifyMySegmentsUpdatedCalled = true
    }
}

//
//  MySegmentsSynchronizerGroupStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class ByKeyFacadeMock: ByKeyFacade {

    var stopSyncCalled = false
    var components = [Key: ByKeyComponentGroup]()
    var loadMySegmentsFromCacheCalled = [String: Bool]()
    var loadMyLargeSegmentsFromCacheCalled = [String: Bool]()
    var startPeriodicSyncCalled = false
    var syncMySegmentsCalled = [String: Bool]()
    var syncMySegmentsKeyCalled = [Key: Bool]()
    var syncMyLargeSegmentsCalled = [String: Bool]()
    var syncMyLargeSegmentsKeyCalled = [Key: Bool]()
    var syncAllCalled = false
    var forceMySegmentsSyncCalled = [String: Bool]()
    var pauseCalled = false
    var resumeCalled = false
    var stopPeriodicSyncCalled = false
    var destroyCalled = false

    var loadAttributesFromCacheCalled = [String: Bool]()

    var matchingKeys: Set<String> {
        return Set(components.keys.map { $0.matchingKey })
    }

    func append(_ group: ByKeyComponentGroup, forKey key: Key) {
        components[key] = group
    }

    func group(forKey key: Key) -> ByKeyComponentGroup? {
        return components[key]
    }

    func remove(forKey key: Key) -> ByKeyComponentGroup? {
        let group = components[key]
        components.removeValue(forKey: key)
        return group
    }

    func removeAndCount(forKey key: Key) -> Int? {
        components.removeValue(forKey: key)
        return components.count
    }

    func loadMySegmentsFromCache(forKey key: String) {
        loadMySegmentsFromCacheCalled[key] = true
    }

    func loadMyLargeSegmentsFromCache(forKey key: String) {
        loadMyLargeSegmentsFromCacheCalled[key] = true
    }

    func loadAttributesFromCache(forKey key: String) {
        loadAttributesFromCacheCalled[key] = true
    }

    func syncMySegments(forKey key: String) {
        syncMySegmentsCalled[key] = true
    }

    func syncMySegments(forKey key: Key) {
        syncMySegmentsKeyCalled[key] = true
    }

    var forceMySegmentsCalledParams = [String: ForceMySegmentsParams]()
    func forceMySegmentsSync(forKey key: String,
                             changeNumbers: SegmentsChangeNumber,
                             delay: Int64) {
        forceMySegmentsSyncCalled[key] = true
        forceMySegmentsCalledParams[key] = ForceMySegmentsParams(segmentsCn:changeNumbers,
                                                                 delay: delay)

//        if let exp = forceMySegmentsSyncExp[key] {
//            exp.fulfill()
//        }
    }

    func startPeriodicSync() {
        startPeriodicSyncCalled = true
    }

    func syncAll() {
        syncAllCalled = true
    }

    var startSyncForKeyCalled = [Key: Bool]()
    func startSync(forKey key: Key) {
        startSyncForKeyCalled[key] = true
    }

    func syncMyLargeSegments(forKey key: String) {
        syncMyLargeSegmentsCalled[key] = true
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

    func isEmpty() -> Bool {
        return components.count == 0
    }

    var notifyMySegmentsUpdatedCalled = false
    var mySegmentsUpdatedMetadataForKey: [String: EventMetadata?] = [:]
    func notifyMySegmentsUpdated(forKey key: String, metadata: EventMetadata? = nil) {
        mySegmentsUpdatedMetadataForKey[key] = metadata
        notifyMySegmentsUpdatedCalled = true
    }

    var notifyMyLargeSegmentsUpdatedCalled = false
    var myLargeSegmentsUpdatedMetadataForKey: [String: EventMetadata?] = [:]
    func notifyMyLargeSegmentsUpdated(forKey key: String, metadata: EventMetadata? = nil) {
        myLargeSegmentsUpdatedMetadataForKey[key] = metadata
        notifyMyLargeSegmentsUpdatedCalled = true
    }
   
    func stopSync() {
        stopSyncCalled = true
    }
}


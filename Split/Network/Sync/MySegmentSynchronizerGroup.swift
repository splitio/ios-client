//
//  MySegmentSynchronizerGroup.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ByKeyRegistry {
    var keys: Set<String> { get }
    func append(_ group: ByKeyComponentGroup, forKey key: String)
    func remove(forKey key: String)
}
protocol ByKeySynchronizer {
    func loadMySegmentsFromCache(forKey key: String)
    func loadAttributesFromCache(forKey key: String)
    func notifyMySegmentsUpdated(forKey key: String)
    func startPeriodicSync()
    func stopPeriodicSync()
    func syncMySegments(forKey key: String)
    func syncAll()
    func forceMySegmentsSync(forKey: String)
    func pause()
    func resume()
    func stop()
}

protocol ByKeyFacade: ByKeyRegistry, ByKeySynchronizer {}

struct ByKeyComponentGroup {
    let eventsManager: SplitEventsManager
    let mySegmentsSynchronizer: MySegmentsSynchronizer
    let attributesStorage: ByKeyAttributesStorage
}

class DefaultByKeyFacade: ByKeyFacade {

    private let byKeyComponents = SyncDictionary<String, ByKeyComponentGroup>()

    var keys: Set<String> {
        return Set(byKeyComponents.all.keys.map { String($0) })
    }

    func append(_ synchronizer: ByKeyComponentGroup, forKey key: String) {
        byKeyComponents.setValue(synchronizer, forKey: key)
    }

    func remove(forKey key: String) {
        byKeyComponents.removeValue(forKey: key)
    }

    func loadMySegmentsFromCache(forKey key: String) {
        byKeyComponents.value(forKey: key)?.mySegmentsSynchronizer.loadMySegmentsFromCache()
    }

    func loadAttributesFromCache(forKey key: String) {
        if let group = byKeyComponents.value(forKey: key) {
            group.attributesStorage.loadLocal()
            group.eventsManager.notifyInternalEvent(.attributesLoadedFromCache)
        }
    }

    func startPeriodicSync() {
        doInAll { group in
            group.mySegmentsSynchronizer.startPeriodicFetching()
        }
    }

    func syncMySegments(forKey key: String) {
        byKeyComponents.value(forKey: key)?.mySegmentsSynchronizer.synchronizeMySegments()
    }

    func syncAll() {
        doInAll { group in
            group.mySegmentsSynchronizer.synchronizeMySegments()
        }
    }

    func forceMySegmentsSync(forKey key: String) {
        byKeyComponents.value(forKey: key)?.mySegmentsSynchronizer.forceMySegmentsSync()
    }

    func notifyMySegmentsUpdated(forKey key: String) {
        byKeyComponents.value(forKey: key)?.eventsManager.notifyInternalEvent(.mySegmentsUpdated)
    }

    func pause() {
        doInAll { group in
            group.mySegmentsSynchronizer.pause()
        }
    }

    func resume() {
        doInAll { group in
            group.mySegmentsSynchronizer.resume()
        }
    }

    func stopPeriodicSync() {
        doInAll { group in
            group.mySegmentsSynchronizer.stopPeriodicFetching()
        }
    }

    func stop() {
        doInAll { group in
            group.attributesStorage.destroy()
            group.mySegmentsSynchronizer.stopPeriodicFetching()
            group.mySegmentsSynchronizer.destroy()
            group.eventsManager.stop()
        }
    }

    private func doInAll(_ action: (ByKeyComponentGroup) -> Void) {
        for (_, sync) in byKeyComponents.all {
            action(sync)
        }
    }
}

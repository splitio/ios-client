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
    func append(_ group: ByKeyComponentGroup, forKey: String)
    func remove(forKey: String)
    func group(forKey: String) -> ByKeyComponentGroup?
}
protocol ByKeySynchronizer {
    func loadMySegmentsFromCache(forKey: String)
    func loadAttributesFromCache(forKey: String)
    func notifyMySegmentsUpdated(forKey: String)
    func startSync(forKey: String)
    func startPeriodicSync()
    func stopPeriodicSync()
    func syncMySegments(forKey: String)
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
    private var isPollingEnabled = Atomic(false)

    var keys: Set<String> {
        return Set(byKeyComponents.all.keys.map { String($0) })
    }

    func group(forKey key: String) -> ByKeyComponentGroup? {
        return byKeyComponents.value(forKey: key)
    }

    func append(_ group: ByKeyComponentGroup, forKey key: String) {
        byKeyComponents.setValue(group, forKey: key)
    }

    func remove(forKey key: String) {
        guard let group = byKeyComponents.value(forKey: key) else { return }
        group.mySegmentsSynchronizer.destroy()
        group.attributesStorage.destroy()
        group.eventsManager.stop()
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
        isPollingEnabled.set(true)
        doInAll { group in
            group.mySegmentsSynchronizer.startPeriodicFetching()
        }
    }

    func startSync(forKey key: String) {
        loadMySegmentsFromCache(forKey: key)
        loadAttributesFromCache(forKey: key)
        syncMySegments(forKey: key)
        if isPollingEnabled.value {
            byKeyComponents.value(forKey: key)?.mySegmentsSynchronizer.startPeriodicFetching()
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
        isPollingEnabled.set(false)
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
        byKeyComponents.removeAll()
    }

    private func doInAll(_ action: (ByKeyComponentGroup) -> Void) {
        let all = byKeyComponents.all
        for (_, sync) in all {
            action(sync)
        }
    }
}

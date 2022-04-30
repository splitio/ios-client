//
//  MySegmentSynchronizerGroup.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ByKeyRegistry {
    var matchingKeys: Set<String> { get }
    func append(_ group: ByKeyComponentGroup, forKey: Key)
    func remove(forKey: Key) -> ByKeyComponentGroup?
    func group(forKey: Key) -> ByKeyComponentGroup?
    func isEmpty() -> Bool
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
    let splitClient: SplitClient
    let eventsManager: SplitEventsManager
    let mySegmentsSynchronizer: MySegmentsSynchronizer
    let attributesStorage: ByKeyAttributesStorage
}

class DefaultByKeyFacade: ByKeyFacade {

    private let byKeyComponents = SplitKeyDictionary<ByKeyComponentGroup>()
    private var isPollingEnabled = Atomic(false)

    var matchingKeys: Set<String> {
        return Set(byKeyComponents.all.keys.map { $0.matchingKey })
    }

    func group(forKey key: Key) -> ByKeyComponentGroup? {
        return byKeyComponents.value(forKey: key)
    }

    func append(_ group: ByKeyComponentGroup, forKey key: Key) {
        byKeyComponents.setValue(group, forKey: key)
    }

    func remove(forKey key: Key) -> ByKeyComponentGroup? {
        guard let group = byKeyComponents.value(forKey: key) else { return nil }
        group.mySegmentsSynchronizer.destroy()
        group.attributesStorage.destroy()
        group.eventsManager.stop()
        byKeyComponents.removeValue(forKey: key)
        return group
    }

    func loadMySegmentsFromCache(forKey key: String) {
        byKeyComponents.values(forMatchingKey: key).forEach { group in
            group.mySegmentsSynchronizer.loadMySegmentsFromCache()
        }
    }

    func loadAttributesFromCache(forKey key: String) {
        doInAll(forMatchingKey: key) { group in
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
            doInAll(forMatchingKey: key) { group in
                group.mySegmentsSynchronizer.startPeriodicFetching()
            }
        }
    }

    func syncMySegments(forKey key: String) {
        doInAll(forMatchingKey: key) { group in
            group.mySegmentsSynchronizer.synchronizeMySegments()
        }
    }

    func syncAll() {
        doInAll { group in
            group.mySegmentsSynchronizer.synchronizeMySegments()
        }
    }

    func forceMySegmentsSync(forKey key: String) {
        doInAll(forMatchingKey: key) { group in
            group.mySegmentsSynchronizer.forceMySegmentsSync()
        }
    }

    func notifyMySegmentsUpdated(forKey key: String) {
        doInAll(forMatchingKey: key) { group in
            group.eventsManager.notifyInternalEvent(.mySegmentsUpdated)
        }
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

    func isEmpty() -> Bool {
        return byKeyComponents.count == 0
    }

    private func doInAll(_ action: (ByKeyComponentGroup) -> Void) {
        let all = byKeyComponents.all
        for (_, sync) in all {
            action(sync)
        }
    }

    private func doInAll(forMatchingKey key: String,
                         action: (ByKeyComponentGroup) -> Void) {

        byKeyComponents.values(forMatchingKey: key).forEach {  group in
            action(group)
        }
    }
}

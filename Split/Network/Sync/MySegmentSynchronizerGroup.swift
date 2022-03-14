//
//  MySegmentSynchronizerGroup.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol MySegmentsSynchronizerGroup {
    func append(_ synchronizer: MySegmentsSynchronizer, forKey key: String)
    func remove(forKey key: String)
    func loadFromCache(forKey key: String)
    func startPeriodicSync()
    func sync(forKey key: String)
    func syncAll()
    func forceSync(forKey: String)
    func pause()
    func resume()
    func stopPeriodicSync()
    func stop()
}

class DefaultMySegmentsSynchronizerGroup: MySegmentsSynchronizerGroup {
    private let synchronizers = ConcurrentDictionary<String, MySegmentsSynchronizer>()

    func append(_ synchronizer: MySegmentsSynchronizer, forKey key: String) {
        synchronizers.setValue(synchronizer, forKey: key)
    }

    func remove(forKey key: String) {
        synchronizers.removeValue(forKey: key)
    }

    func loadFromCache(forKey key: String) {
        synchronizers.value(forKey: key)?.loadMySegmentsFromCache()
    }

    func startPeriodicSync() {
        doInAll { sync in
            sync.startPeriodicFetching()
        }
    }

    func sync(forKey key: String) {
        synchronizers.value(forKey: key)?.synchronizeMySegments()
    }

    func syncAll() {
        doInAll { sync in
            sync.synchronizeMySegments()
        }
    }

    func forceSync(forKey key: String) {
        synchronizers.value(forKey: key)?.forceMySegmentsSync()
    }

    func pause() {
        doInAll { sync in
            sync.pause()
        }
    }

    func resume() {
        doInAll { sync in
            sync.resume()
        }
    }

    func stopPeriodicSync() {
        doInAll { sync in
            sync.stopPeriodicFetching()
        }
    }

    func stop() {
        doInAll { sync in
            sync.stopPeriodicFetching()
            sync.destroy()
        }
    }

    private func doInAll(_ action: (MySegmentsSynchronizer) -> Void) {
        for (_, sync) in synchronizers.all {
            action(sync)
        }
    }
}

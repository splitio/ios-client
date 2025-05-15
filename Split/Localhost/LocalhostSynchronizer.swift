//
//  LocalhostSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 03/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class LocalhostSynchronizer: FeatureFlagsSynchronizer {

    private let featureFlagsStorage: SplitsStorage
    private let featureFlagsDataSource: LocalhostDataSource
    private let eventsManager: SplitEventsManager
    private var isFirstLoad = Atomic<Bool>(true)

    init(featureFlagsStorage: SplitsStorage,
         featureFlagsDataSource: LocalhostDataSource,
         eventsManager: SplitEventsManager) {
        self.featureFlagsStorage = featureFlagsStorage
        self.featureFlagsDataSource = featureFlagsDataSource
        self.eventsManager = eventsManager
        setup()
    }

    func load() {
    }

    func synchronize() {
        featureFlagsDataSource.start()
    }

    func synchronize(changeNumber: Int64?, rbsChangeNumber: Int64?) {
    }

    func startPeriodicSync() {
        featureFlagsDataSource.start()
    }

    func stopPeriodicSync() {
    }

    func notifyKilled() {
    }

    func notifyUpdated() {
    }

    func pause() {
    }

    func resume() {
    }

    func destroy() {
        featureFlagsDataSource.stop()
        featureFlagsStorage.destroy()
    }

    private func setup() {
        featureFlagsDataSource.loadHandler = { [weak self] featureFlags in
            guard let self = self else { return }
            guard let featureFlags = featureFlags else {
                Logger.i("New provided localhost data is empty")
                return
            }

            let values = featureFlags.values.map { $0 as Split }
            let change = ProcessedSplitChange(activeSplits: values,
                                              archivedSplits: [],
                                              changeNumber: -1, updateTimestamp: -1)

            // Update will remove all records before insert new ones
            _ = self.featureFlagsStorage.update(splitChange: change)

            self.eventsManager.notifyInternalEvent(.splitsUpdated)
        }
    }
}

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
        featureFlagsDataSource.start()
    }

    func loadAndSynchronize() {
    }

    func synchronize() {
    }

    func synchronize(changeNumber: Int64) {
    }

    func startPeriodicSync() {
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

    func stop() {
        featureFlagsDataSource.stop()
        featureFlagsStorage.destroy()
    }

    private func setup() {
        featureFlagsDataSource.loadHandler = { [weak self] featureFlags in
            guard let self = self else { return }
            guard let featureFlags = featureFlags else {
                if self.isFirstLoad.getAndSet(false) {
                    self.eventsManager.notifyInternalEvent(.sdkReadyTimeoutReached)
                }
                return
            }

            let values = featureFlags.values.map { $0 as Split }
            let change = ProcessedSplitChange(activeSplits: values,
                                              archivedSplits: [],
                                              changeNumber: -1, updateTimestamp: -1)

            let oldValues = self.featureFlagsStorage.getAll().values.map { $0 as Split }
            // Update will remove all records before insert new ones
            _ = self.featureFlagsStorage.update(splitChange: change)

            if self.isFirstLoad.getAndSet(false) {
                triggerEvents(segments: true)
            } else {
                triggerEvents()
            }
        }
    }

    private func triggerEvents(segments: Bool = false) {
        if segments {
            eventsManager.notifyInternalEvent(.mySegmentsUpdated)
        }
        eventsManager.notifyInternalEvent(.splitsUpdated)
    }
}

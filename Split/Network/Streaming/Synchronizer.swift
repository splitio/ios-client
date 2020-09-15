//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer {
    func runInitialSynchronization()
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startPeriodicRecording()
    func stopPeriodicRecording()
    func pushEvent(event: EventDTO)
    func pushImpression(impression: Impression)
    func flush()
    func destroy()
}

struct SplitApiFacade {
    let splitsFetcher: SplitChangeFetcher
    let mySegmentsFetcher: MySegmentsChangeFetcher
    let refreshableSplitsFetcher: RefreshableSplitFetcher
    let refreshableMySegmentsFetcher: RefreshableMySegmentsFetcher
    let impressionsManager: ImpressionsManager
    let trackManager: TrackManager
}

struct SplitStorageContainer {
    let splitsCache: SplitCacheProtocol
    let mySegmentsCache: MySegmentsCacheProtocol
}

class DefaultSynchronizer: Synchronizer {

    let splitApiFacade: SplitApiFacade
    let splitStorageContainer: SplitStorageContainer
    let splitsSyncBackoff: ReconnectBackoffCounter
    let mySegmentsSyncBackoff: ReconnectBackoffCounter
    let userKey: String // Matching key

    init(userKey: String,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         splitsSyncBackoff: ReconnectBackoffCounter,
         mySegmentsSyncBackoff: ReconnectBackoffCounter) {

        self.userKey = userKey
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
        self.splitsSyncBackoff = splitsSyncBackoff
        self.mySegmentsSyncBackoff = mySegmentsSyncBackoff
    }

    func runInitialSynchronization() {
        
    }

    func synchronizeSplits() {
        // TODO: Check if retry apply here (as Android has)
        _ = try? splitApiFacade.splitsFetcher.fetch(since: splitStorageContainer.splitsCache.getChangeNumber(),
                                                    policy: .network)
    }

    func synchronizeSplits(changeNumber: Int64) {
        // Retry?
        if changeNumber > splitStorageContainer.splitsCache.getChangeNumber() {
            _ = try? splitApiFacade.splitsFetcher.fetch(since: changeNumber, policy: .network)
        }
    }

    func synchronizeMySegments() {
        // Retry?
        _ = try? splitApiFacade.mySegmentsFetcher.fetch(user: userKey, policy: .network)

    }

    func loadAndSynchronizeSplits() {
        // Load?
        _ = try? splitApiFacade.splitsFetcher.fetch(since: splitStorageContainer.splitsCache.getChangeNumber(),
                                                    policy: .networkAndCache)
    }

    func startPeriodicFetching() {
        splitApiFacade.refreshableSplitsFetcher.start()
        splitApiFacade.refreshableMySegmentsFetcher.start()
    }

    func stopPeriodicFetching() {
        splitApiFacade.refreshableSplitsFetcher.stop()
        splitApiFacade.refreshableMySegmentsFetcher.stop()
    }

    func startPeriodicRecording() {
        splitApiFacade.impressionsManager.start()
        splitApiFacade.trackManager.start()
    }

    func stopPeriodicRecording() {
        splitApiFacade.impressionsManager.stop()
        splitApiFacade.trackManager.stop()
    }

    func pushEvent(event: EventDTO) {
        splitApiFacade.trackManager.appendEvent(event: event)
    }

    func pushImpression(impression: Impression) {
        if let splitName = impression.feature {
            splitApiFacade.impressionsManager.appendImpression(impression: impression, splitName: splitName)
        }
    }

    func flush() {
        splitApiFacade.impressionsManager.flush()
        splitApiFacade.trackManager.flush()
    }

    func destroy() {
        splitApiFacade.refreshableSplitsFetcher.stop()
        splitApiFacade.refreshableMySegmentsFetcher.stop()
    }
}

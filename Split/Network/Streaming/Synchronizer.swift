//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer {
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func loadAndSynchronizeSplits()
    func loadSplitsFromCache()
    func loadMySegmentsFromCache()
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

    let userKey: String // Matching key

    init(userKey: String,
         splitsCache: SplitCacheProtocol,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer) {

        self.userKey = userKey
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
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

    }

    func loadSplitsFromCache() {

    }

    func loadMySegmentsFromCache() {

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

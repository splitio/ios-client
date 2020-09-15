//
//  MySegmentsSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

class MySegmentsSynchronizer {

    private let mySegmentsChangeFetcher: MySegmentsChangeFetcher
    private let matchingKey: String
    private let mySegmentsCache: MySegmentsCacheProtocol
    private var splitEventsManager: SplitEventsManager
    private var reconnectBackoffCounter: ReconnectBackoffCounter
    private var firstMySegmentsFetch = true

    init(matchingKey: String, mySegmentsChangeFetcher: MySegmentsChangeFetcher,
         mySegmentsCache: MySegmentsCacheProtocol,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.matchingKey = matchingKey
        self.mySegmentsCache = mySegmentsCache
        self.mySegmentsChangeFetcher = mySegmentsChangeFetcher
        self.splitEventsManager = eventsManager
        self.reconnectBackoffCounter = reconnectBackoffCounter
    }

    func start() {
    }

    func stop() {

    }

    private func fetchFromRemote() {
        while true { // TODO: Check stop status here
            do {
                if let segments = try self.mySegmentsChangeFetcher.fetch(user: self.matchingKey, policy: .network) {
                    Logger.d(segments.debugDescription)
                    fireMySegmentsReadyIsNeeded()
                    reconnectBackoffCounter.resetCounter()
                }
            } catch let error {
                DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherException)
                Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
            }
            // should delay backoff here
        }
    }

    func isInSegments(name: String) -> Bool {
        return mySegmentsCache.isInSegments(name: name)
    }

    private func fireMySegmentsReadyIsNeeded() {
        if self.firstMySegmentsFetch {
            self.firstMySegmentsFetch = false
            self.splitEventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        }
    }
}

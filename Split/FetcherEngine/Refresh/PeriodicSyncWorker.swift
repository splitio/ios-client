//
//  PeriodicSplitsSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 26-Sep-2020
//
//

import Foundation


class PeriodicSyncWorker {

    var fetchTimer: DispatchSourceTimer?
    private let interval: Int
    private let fetchQueue = DispatchQueue.global()

    init(interval: Int) {
        self.interval = interval
    }

    func start() {
        startPeriodicFetch()
    }

    func stop() {
        stopPeriodicFetch()
    }

    private func startPeriodicFetch() {
        fetchTimer = DispatchSource.makeTimerSource(queue: fetchQueue)
        if let timer = fetchTimer {
            timer.schedule(deadline: .now(), repeating: .seconds(self.interval))
            timer.setEventHandler { [weak self] in
                guard let self = self else {
                    return
                }
                self.fetchQueue.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.fetchFromRemote()
                }
            }
            timer.resume()
        }
    }

    private func stopPeriodicFetch() {
        fetchTimer?.cancel()
        fetchTimer = nil
    }

    func fetchFromRemote() {
        fatalError("fetch from remote not implemented")
    }
}

class PeriodicSplitsSyncWorker: PeriodicSyncWorker {

    private let splitChangeFetcher: SplitChangeFetcher
    private let splitCache: SplitCacheProtocol
    private let splitEventsManager: SplitEventsManager

    init(splitChangeFetcher: SplitChangeFetcher,
         splitCache: SplitCacheProtocol,
         interval: Int,
         splitEventsManager: SplitEventsManager) {

        self.splitCache = splitCache
        self.splitChangeFetcher = splitChangeFetcher
        self.splitEventsManager = splitEventsManager
        super.init(interval: interval)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !splitEventsManager.eventAlreadyTriggered(event: .sdkReady) {
            return
        }
        do {
            let splitChanges = try self.splitChangeFetcher.fetch(since: splitCache.getChangeNumber())
            Logger.d(splitChanges.debugDescription)
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem fetching splitChanges: %@", error.localizedDescription)
        }
    }
}

class PeriodicMySegmentsSyncWorker: PeriodicSyncWorker {

    private let mySegmentsFetcher: MySegmentsChangeFetcher
    private let mySegmentsCache: MySegmentsCacheProtocol
    private let userKey: String

    init(userKey: String,
        mySegmentsFetcher: MySegmentsChangeFetcher,
         mySegmentsCache: MySegmentsCacheProtocol,
         interval: Int) {

        self.userKey = userKey
        self.mySegmentsFetcher = mySegmentsFetcher
        self.mySegmentsCache = mySegmentsCache
        super.init(interval: interval)
    }

    override func fetchFromRemote() {
        do {
            let segments = try mySegmentsFetcher.fetch(user: userKey)
            Logger.d(segments.debugDescription)
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

//
//  PeriodicSplitsSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 26-Sep-2020
//
//

import Foundation
protocol PeriodicTimer {
    func trigger()
    func cancel()
    func handler( _ handler: @escaping () -> Void)
}

class DefaultPeriodicTimer: PeriodicTimer {

    private var fetchTimer: DispatchSourceTimer

    init(interval seconds: Int) {
        fetchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        fetchTimer.schedule(deadline: .now(), repeating: .seconds(seconds))
    }

    func trigger() {
        fetchTimer.resume()
    }

    func cancel() {
        fetchTimer.cancel()
    }

    func handler( _ handler: @escaping () -> Void) {
        fetchTimer.setEventHandler(handler: handler)
    }
}

protocol PeriodicSyncWorker {
//    typealias SyncCompletion = (Bool) -> Void
//    var completion: SyncCompletion? { get set }
    func start()
    func stop()
}

class BasePeriodicSyncWorker: PeriodicSyncWorker {

    private var fetchTimer: PeriodicTimer
    private let fetchQueue = DispatchQueue.global()
    private let eventsManager: SplitEventsManager

    init(timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {
        self.eventsManager = eventsManager
        self.fetchTimer = timer
        self.fetchTimer.handler { [weak self] in
            guard let self = self else {
                return
            }
            self.fetchQueue.async {
                self.fetchFromRemote()
            }
        }
    }

    func start() {
        startPeriodicFetch()
    }

    func stop() {
        stopPeriodicFetch()
    }

    private func startPeriodicFetch() {
        fetchTimer.trigger()
    }

    private func stopPeriodicFetch() {
        fetchTimer.cancel()
    }

    func isSdkReadyFired() -> Bool {
        return eventsManager.eventAlreadyTriggered(event: .sdkReady)
    }

    func fetchFromRemote() {
        fatalError("fetch from remote not implemented")
    }
}

class PeriodicSplitsSyncWorker: BasePeriodicSyncWorker {

    private let splitChangeFetcher: SplitChangeFetcher
    private let splitCache: SplitCacheProtocol

    init(splitChangeFetcher: SplitChangeFetcher,
         splitCache: SplitCacheProtocol,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.splitCache = splitCache
        self.splitChangeFetcher = splitChangeFetcher
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
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

class PeriodicMySegmentsSyncWorker: BasePeriodicSyncWorker {

    private let mySegmentsFetcher: MySegmentsChangeFetcher
    private let mySegmentsCache: MySegmentsCacheProtocol
    private let userKey: String

    init(userKey: String,
         mySegmentsFetcher: MySegmentsChangeFetcher,
         mySegmentsCache: MySegmentsCacheProtocol,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.userKey = userKey
        self.mySegmentsFetcher = mySegmentsFetcher
        self.mySegmentsCache = mySegmentsCache
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }
        do {
            let segments = try mySegmentsFetcher.fetch(user: userKey)
            Logger.d(segments.debugDescription)
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

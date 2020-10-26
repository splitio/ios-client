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
    func stop()
    func destroy()
    func handler( _ handler: @escaping () -> Void)
}

class DefaultPeriodicTimer: PeriodicTimer {

    private var interval: Int
    private var fetchTimer: DispatchSourceTimer
    private var isRunning: Atomic<Bool>

    init(interval seconds: Int) {
        self.interval = seconds
        self.isRunning = Atomic(false)
        fetchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    }

    func trigger() {
        if !isRunning.getAndSet(true) {
            fetchTimer.schedule(deadline: .now(), repeating: .seconds(interval))
            fetchTimer.resume()
        }
    }

    func stop() {
        if isRunning.getAndSet(false) {
            fetchTimer.suspend()
        }
    }

    func destroy() {
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
    func destroy()
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

    func destroy() {
        fetchTimer.destroy()
    }

    private func startPeriodicFetch() {
        fetchTimer.trigger()
    }

    private func stopPeriodicFetch() {
        fetchTimer.stop()
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
            _ = try self.splitChangeFetcher.fetch(since: splitCache.getChangeNumber(),
                                                  policy: .network,
                                                  clearCache: false)
            Logger.d("Fetching splits")
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

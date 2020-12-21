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

    private let deadLineInSecs: Int
    private let intervalInSecs: Int
    private var fetchTimer: DispatchSourceTimer
    private var isRunning: Atomic<Bool>

    init(deadline deadlineInSecs: Int, interval intervalInSecs: Int) {
        self.deadLineInSecs = deadlineInSecs
        self.intervalInSecs = intervalInSecs
        self.isRunning = Atomic(false)
        fetchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    }

    convenience init(interval intervalInSecs: Int) {
        self.init(deadline: 0, interval: intervalInSecs)
    }

    func trigger() {
        if !isRunning.getAndSet(true) {
            fetchTimer.schedule(deadline: .now() + .seconds(deadLineInSecs),
                                repeating: .seconds(intervalInSecs))
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
    func pause()
    func resume()
    func stop()
    func destroy()
}

class BasePeriodicSyncWorker: PeriodicSyncWorker {

    private var fetchTimer: PeriodicTimer
    private let fetchQueue = DispatchQueue.global()
    private let eventsManager: SplitEventsManager
    private var isPaused: Atomic<Bool> = Atomic(false)

    init(timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {
        self.eventsManager = eventsManager
        self.fetchTimer = timer
        self.fetchTimer.handler { [weak self] in
            guard let self = self else {
                return
            }
            if self.isPaused.value {
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

    func pause() {
        isPaused.set(true)
    }

    func resume() {
        isPaused.set(false)
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

@available(*, deprecated, message: "This class will be remove in next PR")
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

/// TODO: Rename this class when removing old periodic sync worker on integration
class RevampPeriodicSplitsSyncWorker: BasePeriodicSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }
        do {
            Logger.d("Fetching splits")
            if let change = try self.splitFetcher.execute(since: splitsStorage.changeNumber) {
                splitsStorage.update(splitChange: splitChangeProcessor.process(change))
            }
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


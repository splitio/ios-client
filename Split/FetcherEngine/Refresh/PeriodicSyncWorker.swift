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

    func notifyMySegmentsUpdated() {
        eventsManager.notifyInternalEvent(.mySegmentsUpdated)
    }

    func notifySplitsUpdated() {
        eventsManager.notifyInternalEvent(.splitsUpdated)
    }
}

class PeriodicSplitsSyncWorker: BasePeriodicSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let syncHelper: SplitsSyncHelper
    var changeChecker: SplitsChangesChecker

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.changeChecker = DefaultSplitsChangesChecker()
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor)
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }
        let storedChangeNumber = splitsStorage.changeNumber
        if syncHelper.sync(since: splitsStorage.changeNumber) {
            if changeChecker.splitsHaveChanged(oldChangeNumber: storedChangeNumber,
                                               newChangeNumber: splitsStorage.changeNumber) {
                notifySplitsUpdated()
            }
        }
    }
}

class PeriodicMySegmentsSyncWorker: BasePeriodicSyncWorker {

    private let mySegmentsFetcher: HttpMySegmentsFetcher
    private let mySegmentsStorage: MySegmentsStorage
    private let userKey: String
    private let metricsManager: MetricsManager
    var changeChecker: MySegmentsChangesChecker

    init(userKey: String,
         mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: MySegmentsStorage,
         metricsManager: MetricsManager,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.userKey = userKey
        self.mySegmentsFetcher = mySegmentsFetcher
        self.mySegmentsStorage = mySegmentsStorage
        self.metricsManager = metricsManager
        changeChecker = DefaultMySegmentsChangesChecker()
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }
        do {
            let oldSegments = mySegmentsStorage.getAll()
            if let segments = try mySegmentsFetcher.execute(userKey: userKey) {
                if changeChecker.mySegmentsHaveChanged(old: Array(oldSegments), new: segments) {
                    mySegmentsStorage.set(segments)
                    notifyMySegmentsUpdated()
                }
                Logger.d(segments.debugDescription)
            }
        } catch let error {
            metricsManager.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherException)
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

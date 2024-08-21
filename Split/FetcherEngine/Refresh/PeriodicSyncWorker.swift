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
        fetchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.general)
        self.fetchTimer.resume()
    }

    convenience init(interval intervalInSecs: Int) {
        self.init(deadline: 0, interval: intervalInSecs)
    }

    func trigger() {
        if !isRunning.getAndSet(true) {
            fetchTimer.schedule(deadline: .now() + .seconds(deadLineInSecs),
                                repeating: .seconds(intervalInSecs))
//            fetchTimer.resume()
        }
    }

    func stop() {
        // Not suspending the timer to avoid crashes
        isRunning.set(false)
    }

    func destroy() {
        fetchTimer.cancel()
    }

    func handler( _ handler: @escaping () -> Void) {
        let action = { [weak self] in
            if let self = self, self.isRunning.value {
                handler()
            }
        }
        fetchTimer.setEventHandler(handler: action)
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
    private let fetchQueue = DispatchQueue.general
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
        Logger.i("Fetch from remote not implemented")
    }

    func notifyUpdate(_ events: [SplitInternalEvent]) {
        events.forEach {
            eventsManager.notifyInternalEvent($0)
        }
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
         eventsManager: SplitEventsManager,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.changeChecker = DefaultSplitsChangesChecker()
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           splitConfig: splitConfig)
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }

        guard let result = try? syncHelper.sync(since: splitsStorage.changeNumber) else {
            return
        }
        if result.success, result.featureFlagsUpdated {
            notifyUpdate([.splitsUpdated])
        }
    }
}

class PeriodicMySegmentsSyncWorker: BasePeriodicSyncWorker {

    private let mySegmentsFetcher: HttpMySegmentsFetcher
    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let myLargeSegmentsStorage: ByKeyMySegmentsStorage
    private let userKey: String
    private let telemetryProducer: TelemetryRuntimeProducer?
    var changeChecker: MySegmentsChangesChecker

    init(userKey: String,
         mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: ByKeyMySegmentsStorage,
         myLargeSegmentsStorage: ByKeyMySegmentsStorage,
         telemetryProducer: TelemetryRuntimeProducer?,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager) {

        self.userKey = userKey
        self.mySegmentsFetcher = mySegmentsFetcher
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.telemetryProducer = telemetryProducer
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
            let oldChange = SegmentChange(segments: mySegmentsStorage.getAll().asArray(),
                                          changeNumber: -1)
            let oldLargeChange = SegmentChange(segments: myLargeSegmentsStorage.getAll().asArray(),
                                               changeNumber: myLargeSegmentsStorage.changeNumber)
           if let change = try mySegmentsFetcher.execute(userKey: userKey, headers: nil) {
               let newMsChange = change.mySegmentsChange
               let newMlsChange = change.myLargeSegmentsChange
               let msChanged = changeChecker.mySegmentsHaveChanged(old: oldChange, new: oldChange)
               let mlsChanged = changeChecker.mySegmentsHaveChanged(old: oldChange, new: oldLargeChange)

               if msChanged {
                   mySegmentsStorage.set(newMsChange)
                   Logger.i("My Segments have been updated")
                   Logger.v(newMsChange.segments.joined(separator: ","))
              }

               if mlsChanged {
                   myLargeSegmentsStorage.set(newMlsChange)
                   Logger.i("My Large Segments have been updated")
                   Logger.v(newMlsChange.segments.joined(separator: ","))
               }

               if msChanged || mlsChanged {
                   notifyUpdate([.mySegmentsUpdated])
                   Logger.i("My Segments have been updated")
                   Logger.v(newMsChange.segments.joined(separator: ","))
                   Logger.v(newMlsChange.segments.joined(separator: ","))
                }
            }
        } catch let error {
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

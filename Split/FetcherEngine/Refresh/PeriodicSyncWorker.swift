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

    func notifyUpdate(_ event: SplitInternalEvent, _ metadata: EventMetadata? = nil) {
        eventsManager.notifyInternalEvent(event, metadata: metadata)
    }
}

class PeriodicSplitsSyncWorker: BasePeriodicSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         generalInfoStorage: GeneralInfoStorage,
         ruleBasedSegmentsStorage: RuleBasedSegmentsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentsChangeProcessor = ruleBasedSegmentsChangeProcessor
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           ruleBasedSegmentsChangeProcessor: ruleBasedSegmentsChangeProcessor,
                                           generalInfoStorage: generalInfoStorage,
                                           splitConfig: splitConfig)
        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }

        let changeNumber = splitsStorage.changeNumber
        let rbChangeNumber: Int64 = ruleBasedSegmentsStorage.changeNumber
        guard let result = try? syncHelper.sync(since: changeNumber, rbSince: rbChangeNumber) else {
            return
        }
        
        if result.success, result.featureFlagsUpdated.count > 0 {
            let metadata = EventMetadata(type: .FLAGS_UPDATED, data: result.featureFlagsUpdated)
            notifyUpdate(.splitsUpdated, metadata)
        }
    }
}

class PeriodicMySegmentsSyncWorker: BasePeriodicSyncWorker {

    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let myLargeSegmentsStorage: ByKeyMySegmentsStorage
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let syncHelper: SegmentsSyncHelper

    init(mySegmentsStorage: ByKeyMySegmentsStorage,
         myLargeSegmentsStorage: ByKeyMySegmentsStorage,
         telemetryProducer: TelemetryRuntimeProducer?,
         timer: PeriodicTimer,
         eventsManager: SplitEventsManager,
         syncHelper: SegmentsSyncHelper) {

        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.telemetryProducer = telemetryProducer
        self.syncHelper = syncHelper

        super.init(timer: timer,
                   eventsManager: eventsManager)
    }

    override func fetchFromRemote() {
        // Polling should be done once sdk ready is fired in initial sync
        if !isSdkReadyFired() {
            return
        }

        do {
            let result = try syncHelper.sync(msTill: mySegmentsStorage.changeNumber,
                                             mlsTill: myLargeSegmentsStorage.changeNumber,
                                             headers: nil)
            if result.success {
                if  result.msUpdated || result.mlsUpdated {
                    // For now is not necessary specify which entity was updated
                    notifyUpdate(.mySegmentsUpdated)
                }
            }
        } catch {
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

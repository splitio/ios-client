//
//  PeriodicSplitsSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 26-Sep-2020
//
//

import Foundation

// PeriodicTimer and DefaultPeriodicTimer are defined in Sources/PeriodicRecorderWorker/PeriodicTimer.swift
// and are available via @_exported import (SPM) or direct inclusion (CocoaPods).

protocol PeriodicSyncWorker {
    //    typealias SyncCompletion = (Bool) -> Void
    //    var completion: SyncCompletion? { get set }
    func start()
    func pause()
    func resume()
    func stop()
    func destroy()
}

class BasePeriodicSyncWorker: PeriodicSyncWorker, @unchecked Sendable {

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

    func notifyUpdate(_ event: SplitInternalEvent) {
        let withMetadata = SplitInternalEventWithMetadata(event, metadata: nil)
        notifyUpdate(withMetadata)
    }
    
    func notifyUpdate(_ event: SplitInternalEventWithMetadata) {
        eventsManager.notifyInternalEvent(event)
    }
}

class PeriodicSplitsSyncWorker: BasePeriodicSyncWorker, @unchecked Sendable {

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
        if result.success {
    
            if !result.featureFlagsUpdated.isEmpty {
                let event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: SdkUpdateMetadata(type: .flagsUpdate, names: result.featureFlagsUpdated))
                notifyUpdate(event)
                return // Avoid duplicate notification
            }
            
            if result.rbsUpdated {
                let event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: SdkUpdateMetadata(type: .segmentsUpdate, names: []))
                notifyUpdate(event)
            }
        }
    }
}

class PeriodicMySegmentsSyncWorker: BasePeriodicSyncWorker, @unchecked Sendable {

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
        // Polling should be done once sdk ready is fired in initial sync, and if there are Segments in use.
        // Both storages read the same value so we can use any of them (using myLargeSegmentsStorage).
        if !isSdkReadyFired() || !(myLargeSegmentsStorage.isUsingSegments()) {
            return
        }

        do {
            let result = try syncHelper.sync(msTill: mySegmentsStorage.changeNumber,
                                             mlsTill: myLargeSegmentsStorage.changeNumber,
                                             headers: nil)
            if result.success {
                if  result.msUpdated || result.mlsUpdated {
                    // For now is not necessary specify which entity was updated
                    let event = SplitInternalEventWithMetadata(.mySegmentsUpdated, metadata: SdkUpdateMetadata(type: .segmentsUpdate, names: []))
                    notifyUpdate(event)
                }
            }
        } catch {
            Logger.e("Problem fetching segments: %@", error.localizedDescription)
        }
    }
}

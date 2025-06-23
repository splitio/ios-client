//
//  RetryableSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

protocol RetryableSyncWorker {
    typealias SyncCompletion = (Bool) -> Void
    typealias ErrorHandler = (Error) -> Void
    var completion: SyncCompletion? { get set }
    var errorHandler: ErrorHandler? { get set }
    func start()
    func stop()
}

///
/// Base clase to extend by the classes that retrieves data
/// from servers
/// This class retryies when fetching is not possible do to
/// nettwork connection and http server errors
///
class BaseRetryableSyncWorker: RetryableSyncWorker {

    var completion: SyncCompletion?
    var errorHandler: ErrorHandler?
    private var reconnectBackoffCounter: ReconnectBackoffCounter
    private let eventsManager: SplitEventsManager
    private var isRunning: Atomic<Bool> = Atomic(false)
    private let syncQueue = DispatchQueue.general

    init(eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.eventsManager = eventsManager
        self.reconnectBackoffCounter = reconnectBackoffCounter
    }

    func start() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isRunning.value {
                return
            }
            self.isRunning.set(true)
            self.reconnectBackoffCounter.resetCounter()
            do {
                try self.fetchFromRemoteLoop()
            } catch {
                Logger.e("Error fetching data: \(self)")
                self.errorHandler?(error)
            }
        }
    }

    func stop() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning.set(false)
        }
    }

    private func fetchFromRemoteLoop() throws {
        var success = false
        while isRunning.value, !success {
            success = try fetchFromRemote()
            if !success {
                let retryTimeInSeconds = reconnectBackoffCounter.getNextRetryTime()
                Logger.d("Retrying fetch in: \(retryTimeInSeconds)")
                ThreadUtils.delay(seconds: retryTimeInSeconds)
            }
        }
        self.isRunning.set(false)
        if let handler = completion {
            handler(success)
        }
    }
    
    func notifyUpdate(_ event: SplitInternalEvent) {
        eventsManager.notifyInternalEvent(event, metadata: nil)
    }

    func notifyUpdate(_ event: SplitInternalEvent, metadata: EventMetadata? = nil) {
        eventsManager.notifyInternalEvent(event, metadata: metadata)
    }

    func isSdkReadyTriggered() -> Bool {
        return eventsManager.eventAlreadyTriggered(event: .sdkReady)
    }

    func resetBackoffCounter() {
        reconnectBackoffCounter.resetCounter()
    }

    // This methods should be overrided by child class
    func fetchFromRemote() throws -> Bool {
        Logger.i("fetch from remote not overriden")
        return true
    }
}

class RetryableSplitsSyncWorker: BaseRetryableSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         generalInfoStorage: GeneralInfoStorage,
         ruleBasedSegmentsStorage: RuleBasedSegmentsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentChangeProcessor = ruleBasedSegmentChangeProcessor
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                           generalInfoStorage: generalInfoStorage,
                                           splitConfig: splitConfig)
        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        do {
            let changeNumber = splitsStorage.changeNumber
            let rbChangeNumber = ruleBasedSegmentsStorage.changeNumber
            let result = try syncHelper.sync(since: changeNumber, rbSince: rbChangeNumber, clearBeforeUpdate: false)
            if result.success {
                if !isSdkReadyTriggered() || result.featureFlagsUpdated.count > 0 {
                    let metadata = EventMetadata(type: .FLAGS_UPDATED, data: result.featureFlagsUpdated.description)
                    notifyUpdate(.splitsUpdated, metadata: metadata)
                }
                resetBackoffCounter()
                return true
            }
        } catch {
            Logger.e("Error while fetching splits in method: \(error.localizedDescription)")
            errorHandler?(error)
        }
        return false
    }
}

class RetryableSplitsUpdateWorker: BaseRetryableSyncWorker {

    private let splitsFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor
    private let changeNumber: SplitsUpdateChangeNumber
    private let syncHelper: SplitsSyncHelper
    var changeChecker: SplitsChangesChecker

    init(splitsFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         ruleBasedSegmentsStorage: RuleBasedSegmentsStorage,
         generalInfoStorage: GeneralInfoStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor,
         changeNumber: SplitsUpdateChangeNumber,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         splitConfig: SplitClientConfig) {

        self.splitsFetcher = splitsFetcher
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentChangeProcessor = ruleBasedSegmentChangeProcessor
        self.changeNumber = changeNumber
        self.changeChecker = DefaultSplitsChangesChecker()

        self.syncHelper = SplitsSyncHelper(splitFetcher: splitsFetcher,
                                           splitsStorage: splitsStorage,
                                           ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                           generalInfoStorage: generalInfoStorage,
                                           splitConfig: splitConfig)
        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        let storedChangeNumber = splitsStorage.changeNumber
        let flagsChangeNumber = changeNumber.flags
        if let flagsChangeNumber, flagsChangeNumber <= storedChangeNumber {
            return true
        }

        let storedRbChangeNumber: Int64 = ruleBasedSegmentsStorage.changeNumber
        let rbsChangeNumber = changeNumber.rbs
        if let rbsChangeNumber, rbsChangeNumber <= storedRbChangeNumber {
            return true
        }

        do {
            let result = try syncHelper.sync(since: storedChangeNumber,
                                             rbSince: storedRbChangeNumber,
                                             till: flagsChangeNumber ?? rbsChangeNumber,
                                             clearBeforeUpdate: false,
                                             headers: ServiceConstants.controlNoCacheHeader)
            if result.success {
                if result.featureFlagsUpdated.count > 0 {
                    let metadata = EventMetadata(type: .FLAGS_UPDATED, data: result.featureFlagsUpdated.description)
                    notifyUpdate(.splitsUpdated, metadata: metadata)
                }
                resetBackoffCounter()
                return true
            }
        } catch {
            Logger.e("Error while fetching splits in method \(#function): \(error.localizedDescription)")
            errorHandler?(error)
        }
        Logger.d("Feature flag changes are not updated yet")
        return false
    }
}

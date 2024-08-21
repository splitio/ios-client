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

    func notifyUpdate(_ events: [SplitInternalEvent]) {
        events.forEach {
            eventsManager.notifyInternalEvent($0)
        }
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

///
/// Retrieves segments changes or a user key
/// Also triggers MY SEGMENTS READY event when first fetch is succesful
///
class RetryableMySegmentsSyncWorker: BaseRetryableSyncWorker {

    private let mySegmentsFetcher: HttpMySegmentsFetcher
    private let userKey: String
    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let myLargeSegmentsStorage: ByKeyMySegmentsStorage
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let avoidCache: Bool
    var changeChecker: MySegmentsChangesChecker

    init(userKey: String, mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: ByKeyMySegmentsStorage,
         myLargeSegmentsStorage: ByKeyMySegmentsStorage,
         telemetryProducer: TelemetryRuntimeProducer?,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         avoidCache: Bool) {

        self.userKey = userKey
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
        self.telemetryProducer = telemetryProducer
        self.changeChecker = DefaultMySegmentsChangesChecker()
        self.avoidCache = avoidCache

        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        do {
            // TODO: Update change number logic line will be updated
            let oldChange = SegmentChange(segments: mySegmentsStorage.getAll().asArray(),
                                          changeNumber: mySegmentsStorage.changeNumber)
            let oldLargeChange = SegmentChange(segments: myLargeSegmentsStorage.getAll().asArray(),
                                          changeNumber: myLargeSegmentsStorage.changeNumber)

            if let change = try self.mySegmentsFetcher.execute(userKey: self.userKey, headers: getHeaders()) {
                let mySegmentsChange = change.mySegmentsChange
                let myLargeSegmentsChange = change.myLargeSegmentsChange
                let msChanged =  changeChecker.mySegmentsHaveChanged(old: oldChange,
                                                        new: mySegmentsChange)

                let mlsChanged = changeChecker.mySegmentsHaveChanged(old: oldLargeChange,
                                                        new: myLargeSegmentsChange)
                checkAndUpdate(isChanged: msChanged, change: mySegmentsChange, storage: mySegmentsStorage)
                checkAndUpdate(isChanged: mlsChanged, change: myLargeSegmentsChange, storage: myLargeSegmentsStorage)

                if !isSdkReadyTriggered() || msChanged || mlsChanged {
                    // For now is not necessary specify which entity was updated
                    notifyUpdate([.mySegmentsUpdated])
                }
                resetBackoffCounter()
                return true
            }
        } catch let error {
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
            errorHandler?(error)
        }
        return false
    }

    private func checkAndUpdate(isChanged: Bool, change: SegmentChange, storage: ByKeyMySegmentsStorage) {
        if isChanged {
            storage.set(change)
        }
    }

    private func getHeaders() -> [String: String]? {
        return avoidCache ? ServiceConstants.controlNoCacheHeader : nil
    }
}

class RetryableSplitsSyncWorker: BaseRetryableSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let cacheExpiration: Int
    private let defaultQueryString: String
    private let flagsSpec: String
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         cacheExpiration: Int,
         defaultQueryString: String,
         flagsSpec: String,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.cacheExpiration = cacheExpiration
        self.defaultQueryString = defaultQueryString
        self.flagsSpec = flagsSpec
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           splitConfig: splitConfig)
        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        var changeNumber = splitsStorage.changeNumber
        var clearCache = false
        if changeNumber != -1 {
            if syncHelper.cacheHasExpired(storedChangeNumber: changeNumber,
                                          updateTimestamp: splitsStorage.updateTimestamp,
                                          cacheExpirationInSeconds: Int64(cacheExpiration)) {
                changeNumber = -1
                clearCache = true
            }
        }

        let queryStringHasChanged = defaultQueryString != splitsStorage.splitsFilterQueryString
        let flagsSpecHasChanged = flagsSpec != splitsStorage.flagsSpec
        if queryStringHasChanged || flagsSpecHasChanged {
            if queryStringHasChanged {
                splitsStorage.update(filterQueryString: defaultQueryString)
            }
            if flagsSpecHasChanged {
                splitsStorage.update(flagsSpec: flagsSpec)
            }
            changeNumber = -1
            clearCache = true
        }

        do {
            let result = try syncHelper.sync(since: changeNumber, clearBeforeUpdate: clearCache)
            if result.success {
                if !isSdkReadyTriggered() ||
                    result.featureFlagsUpdated {
                    notifyUpdate([.splitsUpdated])
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
    private let splitChangeProcessor: SplitChangeProcessor
    private let changeNumber: Int64
    private let syncHelper: SplitsSyncHelper
    var changeChecker: SplitsChangesChecker

    init(splitsFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         changeNumber: Int64,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         splitConfig: SplitClientConfig) {

        self.splitsFetcher = splitsFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.changeNumber = changeNumber
        self.changeChecker = DefaultSplitsChangesChecker()

        self.syncHelper = SplitsSyncHelper(splitFetcher: splitsFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           splitConfig: splitConfig)
        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        let storedChangeNumber = splitsStorage.changeNumber
        if changeNumber <= storedChangeNumber {
            return true
        }

        do {
            let result = try syncHelper.sync(since: storedChangeNumber,
                                             till: changeNumber,
                                             clearBeforeUpdate: false,
                                             headers: ServiceConstants.controlNoCacheHeader)
            if result.success {
                if result.featureFlagsUpdated {
                    notifyUpdate([.splitsUpdated])
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

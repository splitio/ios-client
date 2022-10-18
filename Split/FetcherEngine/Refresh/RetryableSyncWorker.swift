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
    var completion: SyncCompletion? { get set }
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
    private var reconnectBackoffCounter: ReconnectBackoffCounter
    private weak var splitEventsManager: SplitEventsManager?
    private var isRunning: Atomic<Bool> = Atomic(false)
    private let syncQueue = DispatchQueue.global()

    init(eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitEventsManager = eventsManager
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
            self.fetchFromRemoteLoop()
        }
    }

    func stop() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning.set(false)
        }
    }

    private func fetchFromRemoteLoop() {
        var success = false
        while isRunning.value, !success {
            success = fetchFromRemote()
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

    func notifySplitsUpdated() {
        splitEventsManager?.notifyInternalEvent(.splitsUpdated)
    }

    func notifyMySegmentsUpdated() {
        splitEventsManager?.notifyInternalEvent(.mySegmentsUpdated)
    }

    func isSdkReadyTriggered() -> Bool {
        return splitEventsManager?.eventAlreadyTriggered(event: .sdkReady) ?? false
    }

    func resetBackoffCounter() {
        reconnectBackoffCounter.resetCounter()
    }

    // This methods should be overrided by child class
    func fetchFromRemote() -> Bool {
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
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let avoidCache: Bool
    var changeChecker: MySegmentsChangesChecker

    init(userKey: String, mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: ByKeyMySegmentsStorage,
         telemetryProducer: TelemetryRuntimeProducer?,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         avoidCache: Bool) {

        self.userKey = userKey
        self.mySegmentsStorage = mySegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
        self.telemetryProducer = telemetryProducer
        self.changeChecker = DefaultMySegmentsChangesChecker()
        self.avoidCache = avoidCache

        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            let oldSegments = mySegmentsStorage.getAll()
            if let segments = try self.mySegmentsFetcher.execute(userKey: self.userKey, headers: getHeaders()) {
                if !isSdkReadyTriggered() ||
                    changeChecker.mySegmentsHaveChanged(old: Array(oldSegments), new: segments) {
                    mySegmentsStorage.set(segments)
                    notifyMySegmentsUpdated()
                }
                resetBackoffCounter()
                return true
            }
        } catch let error {
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
        return false
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
    private let syncHelper: SplitsSyncHelper
    var changeChecker: SplitsChangesChecker

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         cacheExpiration: Int,
         defaultQueryString: String,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.cacheExpiration = cacheExpiration
        self.defaultQueryString = defaultQueryString
        self.changeChecker = DefaultSplitsChangesChecker()
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           splitConfig: splitConfig)
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
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

        if defaultQueryString != splitsStorage.splitsFilterQueryString {
            splitsStorage.update(filterQueryString: defaultQueryString)
            changeNumber = -1
            clearCache = true
        }

        if syncHelper.sync(since: changeNumber, clearBeforeUpdate: clearCache) {
            if !isSdkReadyTriggered() ||
                changeChecker.splitsHaveChanged(oldChangeNumber: changeNumber,
                                                newChangeNumber: splitsStorage.changeNumber) {
                notifySplitsUpdated()
            }
            resetBackoffCounter()
            return true
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
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        let storedChangeNumber = splitsStorage.changeNumber
        if changeNumber <= storedChangeNumber {
            return true
        }

        if syncHelper.sync(since: storedChangeNumber,
                           till: changeNumber,
                           clearBeforeUpdate: false,
                           headers: ServiceConstants.controlNoCacheHeader) {
            if changeChecker.splitsHaveChanged(oldChangeNumber: storedChangeNumber,
                                               newChangeNumber: splitsStorage.changeNumber) {
                notifySplitsUpdated()
            }
            resetBackoffCounter()
            return true
        }
        Logger.d("Split changes are not updated yet")
        return false
    }
}

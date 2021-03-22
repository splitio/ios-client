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
    private var splitEventsManager: SplitEventsManager?
    private var isFirstFetch = Atomic<Bool>(true)
    private var isRunning = Atomic<Bool>(false)
    private let loopQueue = DispatchQueue.global()

    init(eventsManager: SplitEventsManager? = nil,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitEventsManager = eventsManager
        self.reconnectBackoffCounter = reconnectBackoffCounter
    }

    func start() {
        isRunning.set(true)
        loopQueue.async {
            self.fetchFromRemoteLoop()
        }
    }

    func stop() {
        isRunning.set(false)
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
        isRunning.set(false)
        if let handler = completion {
            handler(success)
        }
    }

    func fireReadyIsNeeded(event: SplitInternalEvent) {
        if isFirstFetch.getAndSet(false) {
            splitEventsManager?.notifyInternalEvent(event)
        }
    }

    func resetBackoffCounter() {
        reconnectBackoffCounter.resetCounter()
    }

    // This methods should be overrided by child class
    func fetchFromRemote() -> Bool {
        fatalError("fetch from remote not overriden")
    }
}

///
/// Retrieves segments changes or a user key
/// Also triggers MY SEGMENTS READY event when first fetch is succesful
///
class RetryableMySegmentsSyncWorker: BaseRetryableSyncWorker {

    private let mySegmentsFetcher: HttpMySegmentsFetcher
    private let userKey: String
    private let mySegmentsStorage: MySegmentsStorage
    private let metricsManager: MetricsManager

    init(userKey: String, mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: MySegmentsStorage,
         metricsManager: MetricsManager,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.userKey = userKey
        self.mySegmentsStorage = mySegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
        self.metricsManager = metricsManager
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            if let segments = try self.mySegmentsFetcher.execute(userKey: self.userKey) {
                Logger.d(segments.debugDescription)
                mySegmentsStorage.set(segments)
                fireReadyIsNeeded(event: SplitInternalEvent.mySegmentsUpdated)
                resetBackoffCounter()
                return true
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherException)
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
        return false
    }
}

class RetryableSplitsSyncWorker: BaseRetryableSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let cacheExpiration: Int
    private let defaultQueryString: String
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         cacheExpiration: Int,
         defaultQueryString: String,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.cacheExpiration = cacheExpiration
        self.defaultQueryString = defaultQueryString
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor)
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
            fireReadyIsNeeded(event: SplitInternalEvent.splitsUpdated)
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
    private let controlNoCacheHeader = [ServiceConstants.CacheControlHeader: ServiceConstants.CacheControlNoCache]
    private let syncHelper: SplitsSyncHelper

    init(splitsFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         changeNumber: Int64,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitsFetcher = splitsFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.changeNumber = changeNumber
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitsFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor)
        super.init(reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        if changeNumber < splitsStorage.changeNumber ||
           syncHelper.sync(since: splitsStorage.changeNumber, clearBeforeUpdate: false, headers: controlNoCacheHeader) {
            resetBackoffCounter()
            return true
        }
        Logger.d("Split changes are not updated yet")
        return false
    }
}

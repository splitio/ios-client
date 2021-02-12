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
                fireReadyIsNeeded(event: SplitInternalEvent.mySegmentsAreReady)
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

///
/// Retrieves split changes using stored change number.
/// Also triggers SPLIT READY event when first fetch is succesful
/// TODO: Rename when remove Old  RetryableSplitsSyncWorker
class RevampRetryableSplitsSyncWorker: BaseRetryableSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let cacheExpiration: Int
    private let defaultQueryString: String

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
        super.init(eventsManager: eventsManager, reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            var changeNumber = splitsStorage.changeNumber
            var clearCache = false
            if changeNumber != -1 {
                let timestamp = splitsStorage.updateTimestamp
                let elapsedTime = Int64(Date().timeIntervalSince1970) - timestamp
                if timestamp > 0 && elapsedTime > self.cacheExpiration {
                    changeNumber = -1
                    clearCache = true
                }
            }
            var firstFetch = true
            var nextSince = changeNumber
            while true {
                clearCache = (clearCache || defaultQueryString != splitsStorage.splitsFilterQueryString) && firstFetch
                let splitChange = try self.splitFetcher.execute(since: nextSince)
                let newSince = splitChange.since
                let newTill = splitChange.till
                if clearCache {
                    splitsStorage.clear()
                    splitsStorage.update(filterQueryString: defaultQueryString)
                }
                firstFetch = false
                splitsStorage.update(splitChange: splitChangeProcessor.process(splitChange))
                if newSince == newTill, newTill >= nextSince {
                    fireReadyIsNeeded(event: SplitInternalEvent.splitsAreReady)
                    resetBackoffCounter()
                    return true
                }
                nextSince = newTill
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem fetching splits: %@", error.localizedDescription)
        }
        return false
    }
}

class RevampRetryableSplitsUpdateWorker: BaseRetryableSyncWorker {

    private let splitsFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let changeNumber: Int64

    init(splitsFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         changeNumber: Int64,
         reconnectBackoffCounter: ReconnectBackoffCounter) {

        self.splitsFetcher = splitsFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.changeNumber = changeNumber
        super.init(reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() -> Bool {
        do {
            if changeNumber < splitsStorage.changeNumber {
                resetBackoffCounter()
                return true
            }
            var nextSince = splitsStorage.changeNumber
            while true {
                let splitChange = try self.splitsFetcher.execute(since: nextSince)
                let newSince = splitChange.since
                let newTill = splitChange.till
                splitsStorage.update(splitChange: splitChangeProcessor.process(splitChange))
                if newSince == newTill, newTill >= nextSince {
                    resetBackoffCounter()
                    return true
                }
                nextSince = newTill
            }
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.splitChangeFetcherException)
            Logger.e("Problem updating splits: %@", error.localizedDescription)
        }
        Logger.d("Split changes are not updated yet")
        return false
    }
}


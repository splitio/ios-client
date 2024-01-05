//
//  RetryableSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

struct SyncResult {
    let success: Bool
    let changeNumber: Int64
    let featureFlagsUpdated: Bool
}

class SplitsSyncHelper {

    struct FetchResult {
        let till: Int64
        let featureFlagsUpdated: Bool
    }

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SyncSplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let splitConfig: SplitClientConfig

    private var maxAttempts: Int {
        return splitConfig.cdnByPassMaxAttempts
    }

    private var backoffTimeBaseInSecs: Int {
        return splitConfig.cdnBackoffTimeBaseInSecs
    }

    private var backoffTimeMaxInSecs: Int {
        return splitConfig.cdnBackoffTimeMaxInSecs
    }

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SyncSplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.splitConfig = splitConfig
    }

    func sync(since: Int64,
              till: Int64? = nil,
              clearBeforeUpdate: Bool = false,
              headers: HttpHeaders? = nil) throws -> SyncResult {
        do {
            let res = try tryToSync(since: since,
                                    till: till,
                                    clearBeforeUpdate: clearBeforeUpdate,
                                    headers: headers)

            if res.success {
                return res
            }

            return try tryToSync(since: res.changeNumber,
                                   till: res.changeNumber,
                                   clearBeforeUpdate: clearBeforeUpdate && res.changeNumber == since,
                                   headers: headers,
                                   useTillParam: true)
        } catch let error {
            Logger.e("Problem fetching feature flags: %@", error.localizedDescription)
            throw error
        }
    }

    func tryToSync(since: Int64,
                   till: Int64? = nil,
                   clearBeforeUpdate: Bool = false,
                   headers: HttpHeaders? = nil,
                   useTillParam: Bool = false) throws -> SyncResult {

        let backoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffTimeBaseInSecs,
                                                            maxTimeLimit: backoffTimeMaxInSecs)
        var nextSince = since
        var attemptCount = 0
        let goalTill = till ?? -10
        while attemptCount < maxAttempts {
            let result = try fetchUntil(since: nextSince,
                                       till: useTillParam ? till : nil,
                                       clearBeforeUpdate: clearBeforeUpdate,
                                       headers: headers)
            nextSince = result.till

            if nextSince >= goalTill {
                return SyncResult(success: true,
                                  changeNumber: nextSince,
                                  featureFlagsUpdated: result.featureFlagsUpdated)
            }

            Thread.sleep(forTimeInterval: backoffCounter.getNextRetryTime())
            attemptCount+=1
        }
        return SyncResult(success: false, changeNumber: nextSince, featureFlagsUpdated: false)
    }

    func fetchUntil(since: Int64,
                    till: Int64? = nil,
                    clearBeforeUpdate: Bool = false,
                    headers: HttpHeaders? = nil) throws -> FetchResult {

        var clearCache = clearBeforeUpdate
        var firstFetch = true
        var nextSince = since
        var featureFlagsUpdated = false
        while true {
            clearCache = clearCache && firstFetch
            let splitChange = try self.splitFetcher.execute(since: nextSince,
                                                            till: till,
                                                            headers: headers)
            let newSince = splitChange.since
            let newTill = splitChange.till
            if clearCache {
                splitsStorage.clear()
            }
            firstFetch = false
            if splitsStorage.update(splitChange: splitChangeProcessor.process(splitChange)) {
                featureFlagsUpdated = true
            }
            Logger.i("Feature flag definitions have been updated")
            // Line below commented temporary for debug purposes
            // Logger.v(splitChange.description)
            if newSince == newTill, newTill >= since {
                return FetchResult(till: newTill, featureFlagsUpdated: featureFlagsUpdated)
            }
            nextSince = newTill
        }
    }

    func cacheHasExpired(storedChangeNumber: Int64, updateTimestamp: Int64, cacheExpirationInSeconds: Int64) -> Bool {
        let elepased = Date().unixTimestamp() - updateTimestamp
        return storedChangeNumber > -1
        && updateTimestamp > 0
        && (elepased > cacheExpirationInSeconds)
    }
}

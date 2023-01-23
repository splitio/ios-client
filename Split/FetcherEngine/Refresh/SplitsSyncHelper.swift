//
//  RetryableSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

class SplitsSyncHelper {

    struct SyncResult {
        let success: Bool
        let changeNumber: Int64
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
              headers: HttpHeaders? = nil) -> Bool {
        do {
            let res = try tryToSync(since: since,
                                    till: till,
                                    clearBeforeUpdate: clearBeforeUpdate,
                                    headers: headers)

            if res.success {
                return true
            }

            return ( try tryToSync(since: res.changeNumber,
                                   till: res.changeNumber,
                                   clearBeforeUpdate: clearBeforeUpdate && res.changeNumber == since,
                                   headers: headers,
                                   useTillParam: true) ).success
        } catch let error {
            Logger.e("Problem fetching splits: %@", error.localizedDescription)
        }
        return false
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
            nextSince = try fetchUntil(since: nextSince,
                                       till: useTillParam ? till : nil,
                                       clearBeforeUpdate: clearBeforeUpdate,
                                       headers: headers)

            if nextSince >= goalTill {
                return SyncResult(success: true, changeNumber: nextSince)
            }

            Thread.sleep(forTimeInterval: backoffCounter.getNextRetryTime())
            attemptCount+=1
        }
        return SyncResult(success: false, changeNumber: nextSince)
    }

    func fetchUntil(since: Int64,
                    till: Int64? = nil,
                    clearBeforeUpdate: Bool = false,
                    headers: HttpHeaders? = nil) throws -> Int64 {

        var clearCache = clearBeforeUpdate
        var firstFetch = true
        var nextSince = since
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
            splitsStorage.update(splitChange: splitChangeProcessor.process(splitChange))
            Logger.i("Split definitions have been updated")
            Logger.v(splitChange.description)
            if newSince == newTill, newTill >= since {
                return newTill
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

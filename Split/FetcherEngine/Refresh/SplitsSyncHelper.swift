//
//  RetryableSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

class SplitsSyncHelper {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SyncSplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SyncSplitsStorage,
         splitChangeProcessor: SplitChangeProcessor) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
    }

    func sync(since: Int64, clearBeforeUpdate: Bool = false, headers: HttpHeaders? = nil) -> Bool {
        do {
            var clearCache = clearBeforeUpdate
            var firstFetch = true
            var nextSince = since
            while true {
                clearCache = clearCache && firstFetch
                let splitChange = try self.splitFetcher.execute(since: nextSince, headers: headers)
                let newSince = splitChange.since
                let newTill = splitChange.till
                if clearCache {
                    splitsStorage.clear()
                }
                firstFetch = false
                splitsStorage.update(splitChange: splitChangeProcessor.process(splitChange))
                if newSince == newTill, newTill >= since {
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

    func cacheHasExpired(storedChangeNumber: Int64, updateTimestamp: Int64, cacheExpirationInSeconds: Int64) -> Bool {
        let elepased = Date().unixTimestamp() - updateTimestamp
        return storedChangeNumber > -1
            && updateTimestamp > 0
            && (elepased > cacheExpirationInSeconds)
    }
}

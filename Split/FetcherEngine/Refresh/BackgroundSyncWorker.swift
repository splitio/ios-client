//
//  BackgroundSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 08-Mar-2021
//
//

import Foundation

protocol BackgroundSyncWorker {
    func execute()
}

class BackgroundMySegmentsSyncWorker: BackgroundSyncWorker {

    private let mySegmentsFetcher: HttpMySegmentsFetcher
    private let userKey: String
    private let mySegmentsStorage: MySegmentsStorage

    init(userKey: String, mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: MySegmentsStorage) {

        self.userKey = userKey
        self.mySegmentsStorage = mySegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
    }

    func execute() {
        do {
            if let segments = try self.mySegmentsFetcher.execute(userKey: self.userKey, headers: nil) {
                mySegmentsStorage.set(segments)
            }
        } catch let error {
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
    }
}

class BackgroundSplitsSyncWorker: BackgroundSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let cacheExpiration: Int64
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         cacheExpiration: Int64) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.cacheExpiration = cacheExpiration
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor)
    }

    func execute() {
        var changeNumber = splitsStorage.changeNumber
        var clearCache = false
        if syncHelper.cacheHasExpired(storedChangeNumber: changeNumber,
                                      updateTimestamp: splitsStorage.updateTimestamp,
                                      cacheExpirationInSeconds: cacheExpiration) {
                changeNumber = -1
                clearCache = true
        }

        _ = syncHelper.sync(since: changeNumber, clearBeforeUpdate: clearCache)
    }
}

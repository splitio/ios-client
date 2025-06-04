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
    private let mySegmentsStorage: PersistentMySegmentsStorage
    private let myLargeSegmentsStorage: PersistentMySegmentsStorage

    init(userKey: String, mySegmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: PersistentMySegmentsStorage,
         myLargeSegmentsStorage: PersistentMySegmentsStorage) {

        self.userKey = userKey
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = mySegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
    }

    func execute() {
        do {
            if let change = try self.mySegmentsFetcher.execute(userKey: self.userKey,
                                                               till: nil, headers: nil) {
                mySegmentsStorage.set(change.mySegmentsChange, forKey: userKey)
                myLargeSegmentsStorage.set(change.myLargeSegmentsChange, forKey: userKey)
            }
        } catch let error {
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
    }
}

class BackgroundSplitsSyncWorker: BackgroundSyncWorker {

    private let splitFetcher: HttpSplitFetcher
    private let persistenSplitsStorage: PersistentSplitsStorage
    private let persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let cacheExpiration: Int64
    private let syncHelper: SplitsSyncHelper

    init(splitFetcher: HttpSplitFetcher,
         persistentSplitsStorage: PersistentSplitsStorage,
         persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor,
         cacheExpiration: Int64,
         splitConfig: SplitClientConfig) {

        self.persistenSplitsStorage = persistentSplitsStorage
        self.persistentRuleBasedSegmentsStorage = persistentRuleBasedSegmentsStorage
        self.splitFetcher = splitFetcher
        self.splitChangeProcessor = splitChangeProcessor
        self.cacheExpiration = cacheExpiration
        self.syncHelper = SplitsSyncHelper(splitFetcher: splitFetcher,
                                           splitsStorage: BackgroundSyncSplitsStorage(persistentSplitsStorage: persistentSplitsStorage),
                                           ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage(persistentStorage: persistentRuleBasedSegmentsStorage),
                                           splitChangeProcessor: splitChangeProcessor,
                                           ruleBasedSegmentsChangeProcessor: ruleBasedSegmentsChangeProcessor,
                                           generalInfoStorage: nil, // Pass nil to disable proxy handling for background sync
                                           splitConfig: splitConfig)
    }

    func execute() {
        let changeNumber = persistenSplitsStorage.getChangeNumber()
        let rbChangeNumber = persistentRuleBasedSegmentsStorage.getChangeNumber()
        _ = try? syncHelper.sync(since: changeNumber, rbSince: rbChangeNumber, clearBeforeUpdate: false)
    }
}

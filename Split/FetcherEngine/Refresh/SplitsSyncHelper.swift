//
//  SplitsSyncHelper.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

struct SyncResult {
    let success: Bool
    let changeNumber: Int64
    let rbChangeNumber: Int64?
    let featureFlagsUpdated: Bool
    let rbsUpdated: Bool
}

class SplitsSyncHelper {

    struct FetchResult {
        let till: Int64
        let rbTill: Int64?
        let featureFlagsUpdated: Bool
        let rbsUpdated: Bool
    }

    private let splitFetcher: HttpSplitFetcher
    private let splitsStorage: SyncSplitsStorage
    private let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor
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
         ruleBasedSegmentsStorage: RuleBasedSegmentsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentsChangeProcessor = ruleBasedSegmentsChangeProcessor
        self.splitConfig = splitConfig
    }

    func sync(since: Int64,
              rbSince: Int64,
              till: Int64? = nil,
              clearBeforeUpdate: Bool = false,
              headers: HttpHeaders? = nil) throws -> SyncResult {
        do {
            let res = try tryToSync(since: since,
                                    rbSince: rbSince,
                                    till: till,
                                    clearBeforeUpdate: clearBeforeUpdate,
                                    headers: headers)

            if res.success {
                return res
            }

            return try tryToSync(since: res.changeNumber,
                                   rbSince: res.rbChangeNumber,
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
                   rbSince: Int64? = nil,
                   till: Int64? = nil,
                   rbTill: Int64? = nil,
                   clearBeforeUpdate: Bool = false,
                   headers: HttpHeaders? = nil,
                   useTillParam: Bool = false) throws -> SyncResult {

        let backoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffTimeBaseInSecs,
                                                            maxTimeLimit: backoffTimeMaxInSecs)
        var nextSince = since
        var nextRbSince: Int64? = rbSince
        var attemptCount = 0
        let goalTill = till ?? -10
        let goalRbTill = rbTill ?? -10
        while attemptCount < maxAttempts {
            let result = try fetchUntil(since: nextSince,
                                        rbSince: nextRbSince,
                                       till: useTillParam ? till : nil,
                                       clearBeforeUpdate: clearBeforeUpdate,
                                       headers: headers)
            nextSince = result.till
            nextRbSince = result.rbTill ?? -1

            if nextSince >= goalTill, nextRbSince ?? -1 >= goalRbTill {
                return SyncResult(success: true,
                                  changeNumber: nextSince,
                                  rbChangeNumber: nextRbSince,
                                  featureFlagsUpdated: result.featureFlagsUpdated,
                                  rbsUpdated: result.rbsUpdated)
            }

            Thread.sleep(forTimeInterval: backoffCounter.getNextRetryTime())
            attemptCount+=1
        }
        return SyncResult(success: false,
                          changeNumber: nextSince,
                          rbChangeNumber: nextRbSince,
                          featureFlagsUpdated: false,
                          rbsUpdated: false)
    }

    func fetchUntil(since: Int64,
                    rbSince: Int64?,
                    till: Int64? = nil,
                    clearBeforeUpdate: Bool = false,
                    headers: HttpHeaders? = nil) throws -> FetchResult {

        var clearCache = clearBeforeUpdate
        var firstFetch = true
        var nextSince = since
        var nextRbSince = rbSince
        var featureFlagsUpdated = false
        var rbsUpdated = false
        while true {
            clearCache = clearCache && firstFetch
            let targetingRulesChange = try self.splitFetcher.execute(since: nextSince,
                                                            rbSince: nextRbSince,
                                                            till: till,
                                                            headers: headers)
            let flagsChange = targetingRulesChange.featureFlags
            let newSince = flagsChange.since
            let newTill = flagsChange.till

            let rbsChange = targetingRulesChange.ruleBasedSegments
            let newRbSince = rbsChange.since
            let newRbTill = rbsChange.till
            if clearCache {
                splitsStorage.clear()
                ruleBasedSegmentsStorage.clear()
            }
            firstFetch = false
            if splitsStorage.update(splitChange: splitChangeProcessor.process(targetingRulesChange.featureFlags)) {
                featureFlagsUpdated = true
            }
            
            let processedChange = ruleBasedSegmentsChangeProcessor.process(targetingRulesChange.ruleBasedSegments)
            if ruleBasedSegmentsStorage.update(toAdd: processedChange.toAdd, toRemove: processedChange.toRemove, changeNumber: processedChange.changeNumber) {
                rbsUpdated = true
            }

            Logger.i("Feature flag definitions have been updated")
            // Line below commented temporary for debug purposes
            // Logger.v(splitChange.description)
            let rbSince = rbSince ?? -1
            if newSince == newTill, newTill >= since, newRbSince == newRbTill, newRbTill >= rbSince {
                return FetchResult(till: newTill, rbTill: newRbTill, featureFlagsUpdated: featureFlagsUpdated, rbsUpdated: rbsUpdated)
            }
            nextSince = newTill
            nextRbSince = newRbTill
        }
    }
}

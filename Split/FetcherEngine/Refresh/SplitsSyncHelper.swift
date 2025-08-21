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
    private var ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor
    private let splitConfig: SplitClientConfig
    private let outdatedSplitProxyHandler: OutdatedSplitProxyHandler?

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
         generalInfoStorage: GeneralInfoStorage?,
         splitConfig: SplitClientConfig) {

        self.splitFetcher = splitFetcher
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentsChangeProcessor = ruleBasedSegmentsChangeProcessor
        self.splitConfig = splitConfig

        // Only create a proxy handler if generalInfoStorage is provided.
        // For background sync we don't want the handler, and since generalInfoStorage
        // is only being used for the handler, we use it to know when we don't need it.
        if let storage = generalInfoStorage {
            self.outdatedSplitProxyHandler = OutdatedSplitProxyHandler(
                flagSpec: Spec.flagsSpec,
                generalInfoStorage: storage,
                proxyCheckIntervalMillis: ServiceConstants.proxyCheckIntervalMillis
            )
        } else {
            // No proxy handling for background sync
            self.outdatedSplitProxyHandler = nil
        }
    }

    func sync(since: Int64,
              rbSince: Int64,
              till: Int64? = nil,
              clearBeforeUpdate: Bool = false,
              headers: HttpHeaders? = nil) throws -> SyncResult {
        do {
            // Perform proxy check before syncing if handler exists
            var shouldClearBeforeUpdate = clearBeforeUpdate
            if let proxyHandler = outdatedSplitProxyHandler {
                proxyHandler.performProxyCheck()

                // If we're in recovery mode, we should clear the cache and reset change numbers
                if proxyHandler.isRecoveryMode() {
                    shouldClearBeforeUpdate = true
                }
            }

            let res = try tryToSync(since: since,
                                    rbSince: rbSince,
                                    till: till,
                                    clearBeforeUpdate: shouldClearBeforeUpdate,
                                    headers: headers)

            if res.success {
                // If we were in recovery mode and sync was successful, reset the proxy check timestamp
                if let proxyHandler = outdatedSplitProxyHandler, proxyHandler.isRecoveryMode() {
                    Logger.i("Resetting proxy check timestamp due to successful recovery")
                    proxyHandler.resetProxyCheckTimestamp()
                }
                return res
            }

            return try tryToSync(since: res.changeNumber,
                                   rbSince: res.rbChangeNumber,
                                   till: res.changeNumber,
                                   clearBeforeUpdate: shouldClearBeforeUpdate && res.changeNumber == since,
                                   headers: headers,
                                   useTillParam: true)
        } catch let error {
            Logger.e("Problem fetching feature flags: %@", error.localizedDescription)

            // Check if this is a proxy error and track it if necessary
            if let httpError = error as? HttpError, httpError.isProxyOutdatedError(), let proxyHandler = outdatedSplitProxyHandler {
                proxyHandler.trackProxyError()
            }

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
            // Determine which spec version to use and whether to include rbSince
            let spec = outdatedSplitProxyHandler?.getCurrentSpec() ?? Spec.flagsSpec
            let effectiveRbSince = outdatedSplitProxyHandler?.isFallbackMode() == true ? nil : nextRbSince

            let targetingRulesChange = try self.splitFetcher.execute(since: nextSince,
                                                            rbSince: effectiveRbSince,
                                                            till: till,
                                                            headers: headers,
                                                            spec: spec)
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
            //ruleBasedSegmentsStorage.segmentsInUse = splitsStorage.getSegmentsInUse()
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

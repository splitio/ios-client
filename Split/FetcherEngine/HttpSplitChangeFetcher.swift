//
//  HttpSplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

public enum FecthingPolicy {
    case cacheOnly
    case networkAndCache
    case network
}

class HttpSplitChangeFetcher: NSObject, SplitChangeFetcher {

    private let restClient: RestClientSplitChanges
    private let splitChangeCache: SplitChangeCache
    private let splitChangeValidator: SplitChangeValidator
    private let splitCache: SplitCacheProtocol

    init(restClient: RestClientSplitChanges, splitCache: SplitCacheProtocol) {
        self.restClient = restClient
        self.splitCache = splitCache
        self.splitChangeCache = SplitChangeCache(splitCache: splitCache)
        self.splitChangeValidator = DefaultSplitChangeValidator()
    }

    func fetch(since: Int64, policy: FecthingPolicy, clearCache: Bool) throws -> SplitChange? {

        if policy == .cacheOnly {
            return splitChangeCache.getChanges(since: -1)
        } else if policy == .networkAndCache && !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Split updates will be delayed until host is reachable")
            return splitChangeCache.getChanges(since: -1)
        } else if policy == .network && !restClient.isSdkServerAvailable() {
            return nil
        } else {
            let metricsManager = DefaultMetricsManager.shared
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<SplitChange>?
            let fetchStartTime = Date().unixTimestampInMiliseconds()
            restClient.getSplitChanges(since: since) { result in
                metricsManager.time(microseconds: Date().unixTimestampInMiliseconds() - fetchStartTime,
                                    for: Metrics.Time.splitChangeFetcherGet)
                metricsManager.count(delta: 1, for: Metrics.Counter.splitChangeFetcherStatus200)
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()

            guard let change: SplitChange = try requestResult?.unwrap(),
                splitChangeValidator.validate(change) == nil else {
                throw NSError(domain: "Null split changes", code: -1, userInfo: nil)
            }
            if clearCache {
                splitCache.clear()
            }
            _ = self.splitChangeCache.addChange(splitChange: change)
            return change
        }
    }
}

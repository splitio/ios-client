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
}

class HttpSplitChangeFetcher: NSObject, SplitChangeFetcher {

    private let restClient: RestClientSplitChanges
    private let splitChangeCache: SplitChangeCache
    private let splitChangeValidator: SplitChangeValidator
    private let defaultQueryString: String
    private let splitCache: SplitCacheProtocol

    init(restClient: RestClientSplitChanges, splitCache: SplitCacheProtocol, defaultQueryString: String) {
        self.restClient = restClient
        self.splitCache = splitCache
        self.splitChangeCache = SplitChangeCache(splitCache: splitCache)
        self.splitChangeValidator = DefaultSplitChangeValidator()
        self.defaultQueryString = defaultQueryString
    }

    func fetch(since: Int64, policy: FecthingPolicy) throws -> SplitChange? {

        if policy == .cacheOnly {
            return splitChangeCache.getChanges(since: -1)
        } else if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Split updates will be delayed until host is reachable")
            return splitChangeCache.getChanges(since: -1)
        } else {
            let metricsManager = DefaultMetricsManager.shared
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<SplitChange>?
            let fetchStartTime = Date().unixTimestampInMiliseconds()
            restClient.getSplitChanges(since: since, queryString: defaultQueryString) { result in
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
            if defaultQueryString != splitCache.getQueryString() {
                splitCache.setQueryString(defaultQueryString)
                splitCache.clear()
            }
            _ = self.splitChangeCache.addChange(splitChange: change)
            return change
        }
    }
}

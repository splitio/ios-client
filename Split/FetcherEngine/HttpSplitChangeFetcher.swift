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
    
    private let restClient: RestClient
    private let splitChangeCache: SplitChangeCache?
    
    init(restClient: RestClient, splitCache: SplitCacheProtocol) {
        self.restClient = restClient
        self.splitChangeCache = SplitChangeCache(splitCache: splitCache)
    }
    
    func fetch(since: Int64, policy: FecthingPolicy) throws -> SplitChange? {
        
        if policy == .cacheOnly {
            return self.splitChangeCache?.getChanges(since: -1)
        }
        
        if !restClient.isSdkServerAvailable() {
            return self.splitChangeCache?.getChanges(since: since)
        } else {
            let metricsManager = MetricsManager.shared
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<SplitChange>?
            let fetchStartTime = Date().unixTimestampInMiliseconds()
            restClient.getSplitChanges(since: since) { result in
                metricsManager.time(microseconds: Date().unixTimestampInMiliseconds() - fetchStartTime, for: Metrics.time.splitChangeFetcherGet)
                metricsManager.count(delta: 1, for: Metrics.counter.splitChangeFetcherStatus200)
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()
            
            guard let change: SplitChange = try requestResult?.unwrap(), change.isValid(validator: SplitChangeValidator()) else {
                throw NSError(domain: "Null split changes", code: -1, userInfo: nil)
            }
            _ = self.splitChangeCache?.addChange(splitChange: change)
            return change
        }
    }
    
}

//
//  HttpMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

class HttpMySegmentsFetcher: NSObject, MySegmentsChangeFetcher {
    
    private let restClient: RestClientMySegments
    private let mySegmentsCache: MySegmentsCacheProtocol?
    
    init(restClient: RestClientMySegments, mySegmentsCache: MySegmentsCacheProtocol) {
        self.restClient = restClient
        self.mySegmentsCache = mySegmentsCache
    }
    
    func fetch(user: String, policy: FecthingPolicy) throws -> [String]? {
        
        if policy == .cacheOnly || !self.restClient.isSdkServerAvailable() {
            return self.mySegmentsCache?.getSegments()
        } else {
            let metricsManager = DefaultMetricsManager.shared
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<[String]>?
            let fetchStartTime = Date().unixTimestampInMiliseconds()
            restClient.getMySegments(user: user) { result in
                metricsManager.time(microseconds: Date().unixTimestampInMiliseconds() - fetchStartTime, for: Metrics.time.mySegmentsFetcherGet)
                metricsManager.count(delta: 1, for: Metrics.counter.mySegmentsFetcherStatus200)
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()
            guard let segments = try requestResult?.unwrap() else {
                return nil
            }
            mySegmentsCache?.setSegments(segments)
            return segments
        }
    }
}

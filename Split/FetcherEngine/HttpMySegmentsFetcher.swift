//
//  HttpMySegmentsFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020
//
//

import Foundation

protocol HttpMySegmentsFetcher {
    func execute(userKey: String) throws -> [String]?
}

class DefaultHttpMySegmentsFetcher: HttpMySegmentsFetcher {

    private let restClient: RestClientMySegments
    private let metricsManager: MetricsManager

    init(restClient: RestClientMySegments,
         metricsManager: MetricsManager) {
        self.restClient = restClient
        self.metricsManager = metricsManager
    }

    func execute(userKey: String) throws -> [String]? {
        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. My segment updates will be delayed until host is reachable")
            throw HttpError.serverUnavailable
        }

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<[String]>?
        let fetchStartTime = Date().unixTimestampInMiliseconds()
        restClient.getMySegments(user: userKey) { [weak self] result in
            guard let self = self else {
                return
            }
            self.metricsManager.time(microseconds: Date().unixTimestampInMiliseconds() - fetchStartTime,
                                for: Metrics.Time.mySegmentsFetcherGet)
            self.metricsManager.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherStatus200)
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        guard let segments = try requestResult?.unwrap() else {
            return nil
        }

        return segments
    }
}

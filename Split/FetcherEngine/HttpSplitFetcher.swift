//
//  HttpSplitFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020

import Foundation

protocol HttpSplitFetcher {
    func execute(since: Int64) throws -> SplitChange
}

class DefaultHttpSplitFetcher: HttpSplitFetcher {

    private let restClient: RestClientSplitChanges
    private let metricsManager: MetricsManager

    init(restClient: RestClientSplitChanges, metricsManager: MetricsManager) {
        self.restClient = restClient
        self.metricsManager = metricsManager
    }

    func execute(since: Int64) throws -> SplitChange {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Split updates will be delayed until host is reachable")
            throw HttpError.serverUnavailable
        }

        let metricsManager = self.metricsManager
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

        do {
            if let change: SplitChange = try requestResult?.unwrap() {
                return change
            } else {
                throw GenericError.unknown(message: "Null split changes retrieved")
            }
        } catch {
            Logger.e("Error while retrieving split definitions: \(error.localizedDescription)")
            throw error
        }
    }

}

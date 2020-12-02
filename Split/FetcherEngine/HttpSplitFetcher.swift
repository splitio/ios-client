//
//  HttpSplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

protocol HttpSplitFetcher {
    func execute(since: Int64) throws -> SplitChange?
}

class DefaultHttpSplitFetcher: HttpSplitFetcher {

    private let restClient: RestClientSplitChanges
    private let splitChangeValidator: SplitChangeValidator

    init(restClient: RestClientSplitChanges) {
        self.restClient = restClient
        self.splitChangeValidator = DefaultSplitChangeValidator()
    }

    func execute(since: Int64) throws -> SplitChange? {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Split updates will be delayed until host is reachable")
            throw HttpError.serverUnavailable
        }

        var nextSince = since
        while true {
            let splitChange: SplitChange? = doFetch(since: nextSince)
            guard let change = splitChange, let newSince = change.since, let newTill = change.till else {
                throw NSError(domain: "Null split changes", code: -1, userInfo: nil)
            }

            if newSince == newTill, newTill >= nextSince {
                return change
            }
            nextSince = newTill
        }
        
    }

    private func doFetch(since: Int64) -> SplitChange? {
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

        do {
            if let change: SplitChange = try requestResult?.unwrap(),
                splitChangeValidator.validate(change) == nil {
                return change
            }
        } catch {
            return nil
        }
        return nil
    }
}

//
//  HttpSplitFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020

import Foundation

protocol HttpSplitFetcher {
    func execute(since: Int64, till: Int64?, headers: HttpHeaders?) throws -> SplitChange
}

class DefaultHttpSplitFetcher: HttpSplitFetcher {

    private let restClient: RestClientSplitChanges
    private let syncHelper: SyncHelper
    private let resource = Resource.splits

    init(restClient: RestClientSplitChanges, syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(since: Int64, till: Int64?, headers: HttpHeaders? = nil) throws -> SplitChange {
        Logger.d("Fetching feature flags definitions")
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<SplitChange>?
        let startTime = Date.nowMillis()
        restClient.getSplitChanges(since: since, till: till, headers: headers) { result in
            Logger.v("Time to fetch feature flags: \(Date.interval(millis: startTime))")
            requestResult = result
            semaphore.signal()
        }
        if Thread.isMainThread { print("⚠️ BLOCKINGQUEUE .take() RUNNING ON MAIN ‼️") }
        semaphore.wait()

        do {
            if let change: SplitChange = try requestResult?.unwrap() {
                syncHelper.recordTelemetry(resource: resource, startTime: startTime)
                return change
            }

        } catch {
            try syncHelper.throwIfError(syncHelper.handleError(error, resource: resource, startTime: startTime))
        }

        throw GenericError.unknown(message: "Incorrect feature flags changes retrieved")
    }
}

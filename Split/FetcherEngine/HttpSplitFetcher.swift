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
        Logger.d("Fetching split definitions")
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<SplitChange>?
        let startTime = syncHelper.time()
        restClient.getSplitChanges(since: since, till: till, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()

        do {
            if let change: SplitChange = try requestResult?.unwrap() {
                syncHelper.recordTelemetry(resource: resource, startTime: startTime)
                return change
            }

        } catch {
            try syncHelper.throwIfError(syncHelper.handleError(error, resource: resource, startTime: startTime))
        }

        throw GenericError.unknown(message: "Incorrect split changes retrieved")
    }
}

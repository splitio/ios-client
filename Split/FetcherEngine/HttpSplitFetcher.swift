//
//  HttpSplitFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020

import Foundation

protocol HttpSplitFetcher {
    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders?) throws -> TargetingRulesChange
}

class DefaultHttpSplitFetcher: HttpSplitFetcher {

    private let restClient: RestClientSplitChanges
    private let syncHelper: SyncHelper
    private let resource = Resource.splits

    init(restClient: RestClientSplitChanges, syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders? = nil) throws -> TargetingRulesChange {
        Logger.d("Fetching targeting rules definitions")
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<TargetingRulesChange>?
        let startTime = Date.nowMillis()
        restClient.getSplitChanges(since: since, rbSince: rbSince, till: till, headers: headers, spec: Spec.flagsSpec) { result in
            TimeChecker.logInterval("Time to fetch targeting rules", startTime: startTime)
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()

        do {
            if let targetingRulesChange: TargetingRulesChange = try requestResult?.unwrap() {
                syncHelper.recordTelemetry(resource: resource, startTime: startTime)
                return targetingRulesChange
            }

        } catch {
            try syncHelper.throwIfError(syncHelper.handleError(error, resource: resource, startTime: startTime))
        }

        throw GenericError.unknown(message: "Incorrect targeting rules changes retrieved")
    }
}

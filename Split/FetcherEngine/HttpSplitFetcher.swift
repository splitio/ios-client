//
//  HttpSplitFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020

import Foundation

protocol HttpSplitFetcher {
    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders?, spec: String?) throws -> TargetingRulesChange
}

class DefaultHttpSplitFetcher: HttpSplitFetcher, @unchecked Sendable {

    private let restClient: RestClientSplitChanges
    private let syncHelper: SyncHelper
    private let resource = Resource.splits
    private let timeChecker: TimeChecker

    init(restClient: RestClientSplitChanges, syncHelper: SyncHelper, timeChecker: TimeChecker) {
        self.restClient = restClient
        self.syncHelper = syncHelper
        self.timeChecker = timeChecker
    }

    func execute(since: Int64, rbSince: Int64?, till: Int64?, headers: HttpHeaders? = nil, spec: String? = nil) throws -> TargetingRulesChange {
        Logger.d("Fetching targeting rules definitions")
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<TargetingRulesChange>?
        let startTime = Date.nowMillis()

        // Use provided spec or default to Spec.flagsSpec
        let effectiveSpec = spec ?? Spec.flagsSpec

        let timeChecker = self.timeChecker
        restClient.getSplitChanges(since: since, rbSince: rbSince, till: till, headers: headers, spec: effectiveSpec) { result in
            timeChecker.logInterval("Time to fetch targeting rules", since: startTime)
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

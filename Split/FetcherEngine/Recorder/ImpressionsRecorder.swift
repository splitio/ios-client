//
//  HttpImpressionsRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol HttpImpressionsRecorder {
    func execute(_ items: [ImpressionsTest]) throws
}

class DefaultHttpImpressionsRecorder: HttpImpressionsRecorder {

    private let restClient: RestClientImpressions
    private let syncHelper: SyncHelper
    private let resource = Resource.impressions

    init(restClient: RestClientImpressions,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(_ items: [ImpressionsTest]) throws {
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        let startTime = syncHelper.time()
        restClient.sendImpressions(impressions: items, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                httpError = self.syncHelper.handleError(error, resource: self.resource, startTime: startTime)
            }
            semaphore.signal()
        })
        semaphore.wait()

        try syncHelper.throwIfError(httpError)
        syncHelper.recordTelemetry(resource: resource, startTime: startTime)
    }
}

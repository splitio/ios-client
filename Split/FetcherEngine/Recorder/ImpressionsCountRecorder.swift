//
//  HttpImpressionsCountRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol HttpImpressionsCountRecorder {
    func execute(_ counts: ImpressionsCount) throws
}

class DefaultHttpImpressionsCountRecorder: HttpImpressionsCountRecorder {

    private let restClient: RestClientImpressionsCount
    private let syncHelper: SyncHelper
    private let resource = Resource.impressionsCount

    init(restClient: RestClientImpressionsCount,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(_ counts: ImpressionsCount) throws {

        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        let startTime = syncHelper.time()
        restClient.send(counts: counts, completion: { result in
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

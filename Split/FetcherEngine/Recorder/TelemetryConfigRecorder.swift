//
//  HttpTelemetryConfigRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 7-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol HttpTelemetryConfigRecorder {
    func execute(_ config: TelemetryConfig) throws
}

class DefaultHttpTelemetryConfigRecorder: HttpTelemetryConfigRecorder {

    private let restClient: RestClientTelemetryConfig
    private let syncHelper: SyncHelper
    private let resource = Resource.telemetry

    init(restClient: RestClientTelemetryConfig,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(_ config: TelemetryConfig) throws {

        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        let startTime = syncHelper.time()
        restClient.send(config: config, completion: { result in
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

//
//  HttpTelemetryStatsRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 9-Dic-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol HttpTelemetryStatsRecorder {
    func isEndpointAvailable() -> Bool
    func execute(_ stats: TelemetryStats) throws
}

class DefaultHttpTelemetryStatsRecorder: HttpTelemetryStatsRecorder {

    private let restClient: RestClientTelemetryStats
    private let syncHelper: SyncHelper
    private let resource = Resource.telemetry

    init(restClient: RestClientTelemetryStats,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    // This function should be used from the
    // recorder worker to avoid popping data
    // if endpoint is not available
    func isEndpointAvailable() -> Bool {
        return restClient.isSdkServerAvailable()
    }

    func execute(_ stats: TelemetryStats) throws {

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        let startTime = syncHelper.time()
        restClient.send(stats: stats, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                Logger.e("Telemetry stats error: \(String(describing: error))")
                httpError = self.syncHelper.handleError(error, resource: self.resource, startTime: startTime)
            }
            semaphore.signal()
        })
        semaphore.wait()

        try syncHelper.throwIfError(httpError)
        syncHelper.recordTelemetry(resource: resource, startTime: startTime)
    }
}

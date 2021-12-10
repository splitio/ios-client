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

    init(restClient: RestClientTelemetryStats) {
        self.restClient = restClient
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

        restClient.send(stats: stats, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                Logger.e("Telemetry stats error: \(String(describing: error))")
                httpError = HttpError.unknown(message: error.localizedDescription)
            }
            semaphore.signal()
        })
        semaphore.wait()

        if let error = httpError {
            throw error
        }
    }
}

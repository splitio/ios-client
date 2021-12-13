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

    init(restClient: RestClientTelemetryConfig) {
        self.restClient = restClient
    }

    func execute(_ config: TelemetryConfig) throws {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Events sending will be delayed when host is reachable")
            throw HttpError.serverUnavailable
        }

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?

        restClient.send(config: config, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                Logger.w("Could not send telemetry config: \(String(describing: error))")
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

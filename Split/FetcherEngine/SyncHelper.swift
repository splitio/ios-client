//
//  BaseRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 20-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol SyncHelper {
    func checkEndpointReachability(restClient: RestClient, resource: Resource) throws
    func handleError(_ error: Error, resource: Resource, startTime: Int64) -> HttpError
    func recordHttpError(code: Int, resource: Resource, startTime: Int64)
    func throwIfError(_ error: Error?) throws
    func recordTelemetry(resource: Resource, startTime: Int64)
    func time() -> Int64
}

class DefaultSyncHelper: SyncHelper {

    let telemetryProducer: TelemetryRuntimeProducer?

    init(telemetryProducer: TelemetryRuntimeProducer?) {
        self.telemetryProducer = telemetryProducer
    }

    func checkEndpointReachability(restClient: RestClient, resource: Resource) throws {
        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. \(resource) sync will be delayed when host is reachable")
            throw HttpError.serverUnavailable
        }
    }

    func handleError(_ error: Error, resource: Resource, startTime: Int64) -> HttpError {
        Logger.e("\(resource) -> Error: while syncing data:  \(String(describing: error))")
        if let error = error as? HttpError {
            self.telemetryProducer?.recordHttpError(resource: resource, status: error.code)
            self.telemetryProducer?.recordHttpLatency(resource: resource, latency: Stopwatch.interval(from: startTime))
            return error
        }
        return HttpError.unknown(code: -1, message: error.localizedDescription)
    }

    func throwIfError(_ error: Error?) throws {
        if let error = error {
            throw error
        }
    }

    func recordTelemetry(resource: Resource, startTime: Int64) {
        telemetryProducer?.recordLastSync(resource: resource, time: time())
        telemetryProducer?.recordHttpLatency(resource: resource, latency: Stopwatch.interval(from: startTime))
    }

    func recordHttpError(code: Int, resource: Resource, startTime: Int64) {
        self.telemetryProducer?.recordHttpError(resource: resource, status: code)
        self.telemetryProducer?.recordHttpLatency(resource: resource, latency: Stopwatch.interval(from: startTime))
    }

    func time() -> Int64 {
        if telemetryProducer == nil {
            return 0
        }
        return Date().unixTimestampInMiliseconds()
    }
}

//
//  TelemetryStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

// MARK: Config Telemtry
protocol TelemetryInitProducer {
    func recordNonReadyUsage()
}

protocol TelemetryInitConsumer {
    func getNonReadyUsages()
}

// MARK: Evaluation Telemetry
protocol TelemetryEvaluationProducer {
    func recordLatency(method: String, latency: Int64)
    func recordException(method: String)
}

protocol TelemetryEvaluationConsumer {
    func popExceptions() -> TelemetryMethodExceptions
    func popLatencies() -> TelemetryMethodLatencies
}

enum ImpressionsDataType {
}
enum EventsDataRecords {
}
enum Resource {
}
enum LastSynchronizationRecords {
}


protocol TelemetryRuntimeProducer {
    func addTag(tag: String)
    func recordImpressionStats(dataType: ImpressionsDataType, count: Int)
    func recordEventStats(dataType: EventsDataRecords, count: Int)
    func recordSuccessfulSync(resource: LastSynchronizationRecords, time: Int64)
    func recordSyncError(resource: Resource, status: Int)
    func recordSyncLatency(resource: TelemetryHttpLatencies, latency: Int64)
    func recordAuthRejections()
    func recordTokenRefreshes()
    func recordStreamingEvents(streamingEvent: TelemetryStreamingEvent)
    func recordSessionLength(sessionLength: Int64)
}

protocol TelemetryRuntimeConsumer {
    func getImpressionsStats(data: ImpressionsDataType) -> Int
    func getEventStats(type: EventsDataRecords) -> Int
    func getLastSynchronization() -> TelemetryLastSynchronization
    func popHTTPErrors() -> TelemetryHttpErrors
    func popHTTPLatencies() -> TelemetryHttpLatencies
    func popAuthRejections() -> Int64
    func popTokenRefreshes() -> Int64
    func spopStreamingEvents() -> [TelemetryStreamingEvent]
    func popTags() -> [String]
    func getSessionLength() -> Int64
}

protocol TelemetryProducer: TelemetryInitProducer,
                         TelemetryEvaluationProducer,
                         TelemetryRuntimeProducer {
}

protocol TelemetryConsumer: TelemetryInitConsumer,
                         TelemetryEvaluationConsumer,
                         TelemetryRuntimeConsumer {
}

protocol TelemetryStorage: TelemetryProducer, TelemetryConsumer {
}

// Dummy class to make the project compile until implementation is done
class InMemoryTelemetryStorage: TelemetryStorage {
    func recordNonReadyUsage() {

    }

    func recordLatency(method: String, latency: Int64) {

    }

    func recordException(method: String) {

    }

    func addTag(tag: String) {

    }

    func recordImpressionStats(dataType: ImpressionsDataType, count: Int) {

    }

    func recordEventStats(dataType: EventsDataRecords, count: Int) {

    }

    func recordSuccessfulSync(resource: LastSynchronizationRecords, time: Int64) {

    }

    func recordSyncError(resource: Resource, status: Int) {

    }

    func recordSyncLatency(resource: TelemetryHttpLatencies, latency: Int64) {

    }

    func recordAuthRejections() {

    }

    func recordTokenRefreshes() {

    }

    func recordStreamingEvents(streamingEvent: TelemetryStreamingEvent) {

    }

    func recordSessionLength(sessionLength: Int64) {

    }

    func getNonReadyUsages() {

    }

    func popExceptions() -> TelemetryMethodExceptions {
        return TelemetryMethodExceptions(treatment: 0,
                                         treatments: 0,
                                         treatmentWithConfig: 0,
                                         treatmentsWithConfig: 0,
                                         track: 0)
    }

    func popLatencies() -> TelemetryMethodLatencies {
        return TelemetryMethodLatencies(treatment: [0],
                                        treatments: [0],
                                        treatmentWithConfig: [0],
                                        treatmentsWithConfig: [0],
                                        track: [0])
    }

    func getImpressionsStats(data: ImpressionsDataType) -> Int {

    }

    func getEventStats(type: EventsDataRecords) -> Int {

    }

    func getLastSynchronization() -> TelemetryLastSynchronization {
        return TelemetryLastSynchronization(splits: 0, impressions: 0,
                                            impressionsCount: 0, events: 0, token: 0,
                                            telemetry: 0, mySegments: 0)
    }

    func popHTTPErrors() -> TelemetryHttpErrors {
        let val: [Int: Int64] = [0: 0]
        return TelemetryHttpErrors(splits: val,
                                   mySegments: val, impressions: val,
                                   impressionsCount: val,
                                   events: val,
                                   token: val,
                                   telemetry: val)
    }

    func popHTTPLatencies() -> TelemetryHttpLatencies {
        let val: [Int64] = [0]
        return TelemetryHttpLatencies(splits: val, mySegments: val,
                                      impressions: val, impressionsCount: val,
                                      events: val, token: val, telemetry: val)
    }

    func popAuthRejections() -> Int64 {
        return 0
    }

    func popTokenRefreshes() -> Int64 {
        return 0
    }

    func spopStreamingEvents() -> [TelemetryStreamingEvent] {
        return []
    }

    func popTags() -> [String] {
        return []
    }

    func getSessionLength() -> Int64 {
        return 0
    }


}

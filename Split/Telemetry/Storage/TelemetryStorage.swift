//
//  TelemetryStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum TelemetryImpressionsDataType: CaseIterable {
    case queued
    case dropped
    case deduped
}

enum TelemetryEventsDataType: CaseIterable {
    case queued
    case dropped
}

enum TelemetryMethod: CaseIterable {
    case treatment
    case treatments
    case treatmentWithConfig
    case treatmentsWithConfig
    case track
}

enum Resource: CaseIterable {
    case splits
    case mySegments
    case impressions
    case impressionsCount
    case events
    case telemetry
    case token
    case uniqueKeys
}

enum TelemetryInitCounter: CaseIterable {
    case nonReadyUsages
}

// MARK: Config Telemtry
protocol TelemetryInitProducer {
    func recordNonReadyUsage()
    func recordFactories(active: Int, redundant: Int)
    func recordTimeUntilReady(_ time: Int64)
    func recordTimeUntilReadyFromCache(_ time: Int64)
}

protocol TelemetryInitConsumer {
    func getNonReadyUsages() -> Int
    func getActiveFactories() -> Int
    func getRedundantFactories() -> Int
    func getTimeUntilReady() -> Int64
    func getTimeUntilReadyFromCache() -> Int64
}

// MARK: Evaluation Telemetry
protocol TelemetryEvaluationProducer {
    func recordLatency(method: TelemetryMethod, latency: Int64)
    func recordException(method: TelemetryMethod)
}

protocol TelemetryEvaluationConsumer {
    func popMethodLatencies() -> TelemetryMethodLatencies
    func popMethodExceptions() -> TelemetryMethodExceptions
}

protocol TelemetryRuntimeProducer {

    func recordImpressionStats(type: TelemetryImpressionsDataType, count: Int)
    func recordEventStats(type: TelemetryEventsDataType, count: Int)
    func recordLastSync(resource: Resource, time: Int64)
    func recordHttpError(resource: Resource, status: Int)
    func recordHttpLatency(resource: Resource, latency: Int64)
    func recordAuthRejections()
    func recordTokenRefreshes()
    func recordStreamingEvent(type: TelemetryStreamingEventType, data: Int64?)
    func addTag(tag: String)
    func recordSessionLength(sessionLength: Int64)
}

protocol TelemetryRuntimeConsumer {
    func getImpressionStats(type: TelemetryImpressionsDataType) -> Int
    func getEventStats(type: TelemetryEventsDataType) -> Int
    func getLastSync() -> TelemetryLastSync
    func popHttpErrors() -> TelemetryHttpErrors
    func popHttpLatencies() -> TelemetryHttpLatencies
    func popAuthRejections() -> Int
    func popTokenRefreshes() -> Int
    func popStreamingEvents() -> [TelemetryStreamingEvent]
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

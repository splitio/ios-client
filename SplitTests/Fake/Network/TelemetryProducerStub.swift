//
//  TelemetryProducerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class TelemetryStorageStub: TelemetryStorage {

    var popTagsCallCount = 0

    func recordLastSync(resource: TelemetryResource, time: Int64) {
    }

    func recordHttpLatency(resource: TelemetryResource, latency: Int64) {
    }

    func getNonReadyUsages() -> Int {
        return 0
    }

    func popAuthRejections() -> Int {
        return 0
    }

    func popTokenRefreshes() -> Int {
        return 0
    }

    func popStreamingEvents() -> [TelemetryStreamingEvent] {
        return []
    }


    func recordNonReadyUsage() {

    }

    func recordLatency(method: TelemetryMethod, latency: Int64) {

    }

    func recordException(method: TelemetryMethod) {

    }

    func addTag(tag: String) {
    }

    func recordImpressionStats(type: TelemetryImpressionsDataType, count: Int) {

    }

    func recordEventStats(type: TelemetryEventsDataType, count: Int) {

    }

    func recordHttpError(resource: TelemetryResource, status: Int) {

    }

    func recordAuthRejections() {

    }

    func recordTokenRefreshes() {

    }

    func recordStreamingEvent(type: TelemetryStreamingEventType, data: Int64, timestamp: Int64) {

    }

    func recordSessionLength(sessionLength: Int64) {

    }

    func popMethodExceptions() -> TelemetryMethodExceptions {
        return TelemetryMethodExceptions(treatment: 0,
                                         treatments: 0,
                                         treatmentWithConfig: 0,
                                         treatmentsWithConfig: 0,
                                         track: 0)
    }

    func popMethodLatencies() -> TelemetryMethodLatencies {
        return TelemetryMethodLatencies(treatment: [0],
                                        treatments: [0],
                                        treatmentWithConfig: [0],
                                        treatmentsWithConfig: [0],
                                        track: [0])
    }

    func getImpressionStats(type: TelemetryImpressionsDataType) -> Int {
        return 0
    }

    func getEventStats(type: TelemetryEventsDataType) -> Int {
        return 0
    }

    func getLastSync() -> TelemetryLastSync {
        return TelemetryLastSync(splits: 0, impressions: 0,
                                            impressionsCount: 0, events: 0, token: 0,
                                            telemetry: 0, mySegments: 0)
    }

    func popHttpErrors() -> TelemetryHttpErrors {
        let val: [Int: Int] = [0: 0]
        return TelemetryHttpErrors(splits: val,
                                   mySegments: val, impressions: val,
                                   impressionsCount: val,
                                   events: val,
                                   token: val,
                                   telemetry: val)
    }

    func popHttpLatencies() -> TelemetryHttpLatencies {
        let val: [Int] = [0]
        return TelemetryHttpLatencies(splits: val, mySegments: val,
                                      impressions: val, impressionsCount: val,
                                      events: val, token: val, telemetry: val)
    }

    func popTags() -> [String] {
        popTagsCallCount+=1
        return []
    }

    func getSessionLength() -> Int64 {
        return 0
    }

    func recordActiveFactories(count: Int) {
    }

    func recordRedundantFactories(count: Int) {
    }

    func recordTimeUntilReady(_ time: Int64) {
    }

    func getActiveFactories() -> Int {
        return 0
    }

    func getRedundantFactories() -> Int {
        return 0
    }

    func getTimeUntilReady() -> Int64 {
        return 0
    }
}

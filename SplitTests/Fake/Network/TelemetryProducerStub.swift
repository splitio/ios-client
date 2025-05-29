//
//  TelemetryProducerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class TelemetryStorageStub: TelemetryStorage {
    var nonReadyUsageCallCount = 0
    var popTagsCallCount = 0
    var recordHttpErrorCallCount = 0
    var recordHttpLastSyncCallCount = 0
    var recordHttpLatencyCallCount = 0
    var recordTokenRefreshesCallCount = 0
    var recordAuthRejectionCallCount = 0
    var recordActiveFactoriesCallCount: Int = 0
    var recordRedundantFactoriessCallCount: Int = 0
    var recordTimeUntilReadyCallCount: Int = 0
    var recordTimeUntilReadyFromCacheCallCount: Int = 0
    var streamingEvents = [TelemetryStreamingEventType: Int]()
    var methodLatencies = [TelemetryMethod: Int]()
    var impressions = [TelemetryImpressionsDataType: Int]()
    var events = [TelemetryEventsDataType: Int]()

    var isFactoryDataRecorded = Atomic<Bool>(false)

    func recordLastSync(resource: Resource, time: Int64) {
        recordHttpLastSyncCallCount += 1
    }

    func recordHttpLatency(resource: Resource, latency: Int64) {
        recordHttpLatencyCallCount += 1
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
        nonReadyUsageCallCount += 1
    }

    func recordLatency(method: TelemetryMethod, latency: Int64) {
        methodLatencies[method] = (methodLatencies[method] ?? 0) + 1
    }

    func recordException(method: TelemetryMethod) {}

    func addTag(tag: String) {}

    func recordImpressionStats(type: TelemetryImpressionsDataType, count: Int) {
        impressions[type] = (impressions[type] ?? 0) + 1
    }

    func recordEventStats(type: TelemetryEventsDataType, count: Int) {
        events[type] = (events[type] ?? 0) + 1
    }

    func recordHttpError(resource: Resource, status: Int) {
        recordHttpErrorCallCount += 1
    }

    func recordAuthRejections() {}

    func recordTokenRefreshes() {}

    func recordStreamingEvent(type: TelemetryStreamingEventType, data: Int64?) {
        streamingEvents[type] = (streamingEvents[type] ?? 0) + 1
    }

    var recordSessionLengthCalled = false
    func recordSessionLength(sessionLength: Int64) {
        recordSessionLengthCalled = true
    }

    func popMethodExceptions() -> TelemetryMethodExceptions {
        return TelemetryMethodExceptions(
            treatment: 0,
            treatments: 0,
            treatmentWithConfig: 0,
            treatmentsWithConfig: 0,
            track: 0)
    }

    func popMethodLatencies() -> TelemetryMethodLatencies {
        return TelemetryMethodLatencies(
            treatment: [0],
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
        return TelemetryLastSync(
            splits: 0,
            impressions: 0,
            impressionsCount: 0,
            events: 0,
            token: 0,
            telemetry: 0,
            mySegments: 0)
    }

    func popHttpErrors() -> TelemetryHttpErrors {
        let val = [0: 0]
        return TelemetryHttpErrors(
            splits: val,
            mySegments: val,
            impressions: val,
            impressionsCount: val,
            events: val,
            token: val,
            telemetry: val)
    }

    func popHttpLatencies() -> TelemetryHttpLatencies {
        let val = [0]
        return TelemetryHttpLatencies(
            splits: val,
            mySegments: val,
            impressions: val,
            impressionsCount: val,
            events: val,
            token: val,
            telemetry: val)
    }

    func popTags() -> [String] {
        popTagsCallCount += 1
        return []
    }

    func getSessionLength() -> Int64 {
        return 0
    }

    func recordFactories(active: Int, redundant: Int) {
        recordActiveFactoriesCallCount += 1
        recordRedundantFactoriessCallCount += 1
    }

    func recordTimeUntilReady(_ time: Int64) {
        recordTimeUntilReadyCallCount += 1
    }

    func recordTimeUntilReadyFromCache(_ time: Int64) {
        recordTimeUntilReadyFromCacheCallCount += 1
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

    func getTimeUntilReadyFromCache() -> Int64 {
        return 0
    }

    var recordUpdatesFromSseExp: XCTestExpectation?
    var recordUpdatesFromSseCalled = false
    func recordUpdatesFromSse(type: TelemetryUpdatesFromSseType) {
        recordUpdatesFromSseCalled = true
        recordUpdatesFromSseExp?.fulfill()
    }

    var popUpdatesFromSseCalled = false
    func popUpdatesFromSse() -> TelemetryUpdatesFromSse {
        popUpdatesFromSseCalled = true
        return TelemetryUpdatesFromSse(splits: 0, mySegments: 0)
    }

    var totalFlagSetsCount = 0
    func recordTotalFlagSets(_ value: Int) {
        totalFlagSetsCount = value
    }

    var invalidFlagSetsCount = 0
    func recordInvalidFlagSets(_ value: Int) {
        invalidFlagSetsCount = value
    }

    func getTotalFlagSets() -> Int {
        return totalFlagSetsCount
    }

    func getInvalidFlagSets() -> Int {
        return invalidFlagSetsCount
    }
}

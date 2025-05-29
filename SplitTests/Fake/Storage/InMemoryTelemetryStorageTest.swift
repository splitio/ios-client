//
//  InMemoryTelemetryStorageTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 06-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class InMemoryTelemetryStorageTest: XCTestCase {
    var storage: TelemetryStorage!

    var rnd: Int64 {
        return Int64.random(in: 1 ..< 5) * 100000
    }

    override func setUp() {
        storage = InMemoryTelemetryStorage()
    }

    func testLatencies() {
        recordLatency(method: .treatment, count: 3)
        recordLatency(method: .treatments, count: 2)
        recordLatency(method: .treatmentWithConfig, count: 4)
        recordLatency(method: .treatmentsWithConfig, count: 9)

        let latencies = storage.popMethodLatencies()
        let emptyPopLatencies = storage.popMethodLatencies()

        recordLatency(method: .track, count: 1)
        let newPopLatencies = storage.popMethodLatencies()

        XCTAssertEqual(3, sum(latencies.treatment))
        XCTAssertEqual(2, sum(latencies.treatments))
        XCTAssertEqual(4, sum(latencies.treatmentWithConfig))
        XCTAssertEqual(9, sum(latencies.treatmentsWithConfig))
        XCTAssertEqual(0, sum(latencies.track))

        XCTAssertEqual(0, sum(emptyPopLatencies.treatment))
        XCTAssertEqual(0, sum(emptyPopLatencies.treatments))
        XCTAssertEqual(0, sum(emptyPopLatencies.treatmentWithConfig))
        XCTAssertEqual(0, sum(emptyPopLatencies.treatmentsWithConfig))
        XCTAssertEqual(0, sum(emptyPopLatencies.track))

        XCTAssertEqual(1, sum(newPopLatencies.track))
    }

    func testExceptions() {
        recordException(method: .treatment, count: 3)
        recordException(method: .treatments, count: 2)
        recordException(method: .treatmentWithConfig, count: 4)
        recordException(method: .treatmentsWithConfig, count: 9)

        let exceptions = storage.popMethodExceptions()
        let emptyExceptions = storage.popMethodExceptions()

        XCTAssertEqual(3, exceptions.treatment)
        XCTAssertEqual(2, exceptions.treatments)
        XCTAssertEqual(4, exceptions.treatmentWithConfig)
        XCTAssertEqual(9, exceptions.treatmentsWithConfig)
        XCTAssertEqual(0, exceptions.track)

        XCTAssertEqual(0, emptyExceptions.treatment ?? 0)
        XCTAssertEqual(0, emptyExceptions.treatments ?? 0)
        XCTAssertEqual(0, emptyExceptions.treatmentWithConfig ?? 0)
        XCTAssertEqual(0, emptyExceptions.treatmentsWithConfig ?? 0)
        XCTAssertEqual(0, emptyExceptions.track ?? 0)
    }

    func testImpression() {
        recordImpression(type: .deduped, countStat: 1, count: 10)
        recordImpression(type: .dropped, countStat: 2, count: 5)
        recordImpression(type: .queued, countStat: 5, count: 2)

        let deduped = storage.getImpressionStats(type: .deduped)
        let dropped = storage.getImpressionStats(type: .dropped)
        let queued = storage.getImpressionStats(type: .queued)

        recordImpression(type: .deduped, countStat: 1, count: 1)
        recordImpression(type: .dropped, countStat: 1, count: 1)
        recordImpression(type: .queued, countStat: 1, count: 1)

        let deduped1 = storage.getImpressionStats(type: .deduped)
        let dropped1 = storage.getImpressionStats(type: .dropped)
        let queued1 = storage.getImpressionStats(type: .queued)

        XCTAssertEqual(10, deduped)
        XCTAssertEqual(10, dropped)
        XCTAssertEqual(10, queued)

        XCTAssertEqual(11, deduped1)
        XCTAssertEqual(11, dropped1)
        XCTAssertEqual(11, queued1)
    }

    func testEvent() {
        recordEvent(type: .dropped, countStat: 2, count: 5)
        recordEvent(type: .queued, countStat: 5, count: 2)

        let dropped = storage.getEventStats(type: .dropped)
        let queued = storage.getEventStats(type: .queued)

        recordEvent(type: .dropped, countStat: 1, count: 1)
        recordEvent(type: .queued, countStat: 1, count: 1)

        let dropped1 = storage.getEventStats(type: .dropped)
        let queued1 = storage.getEventStats(type: .queued)

        XCTAssertEqual(10, dropped)
        XCTAssertEqual(10, queued)

        XCTAssertEqual(11, dropped1)
        XCTAssertEqual(11, queued1)
    }

    func testLastSync() {
        storage.recordLastSync(resource: .splits, time: 1000)
        storage.recordLastSync(resource: .mySegments, time: 1000)
        storage.recordLastSync(resource: .impressions, time: 1000)
        storage.recordLastSync(resource: .impressionsCount, time: 1000)
        storage.recordLastSync(resource: .telemetry, time: 1000)
        storage.recordLastSync(resource: .token, time: 1000)

        let sync = storage.getLastSync()

        storage.recordLastSync(resource: .impressions, time: 2000)
        storage.recordLastSync(resource: .impressionsCount, time: 2000)
        storage.recordLastSync(resource: .telemetry, time: 2000)
        storage.recordLastSync(resource: .token, time: 2000)

        let sync1 = storage.getLastSync()

        XCTAssertEqual(1000, sync.splits)
        XCTAssertEqual(1000, sync.mySegments)
        XCTAssertEqual(1000, sync.impressions)
        XCTAssertEqual(1000, sync.impressionsCount)
        XCTAssertEqual(1000, sync.telemetry)
        XCTAssertEqual(1000, sync.token)

        XCTAssertEqual(1000, sync1.splits)
        XCTAssertEqual(1000, sync1.mySegments)
        XCTAssertEqual(2000, sync1.impressions)
        XCTAssertEqual(2000, sync1.impressionsCount)
        XCTAssertEqual(2000, sync1.telemetry)
        XCTAssertEqual(2000, sync1.token)
    }

    func testHttpErrors() {
        recordHttpError(resource: .splits, factor: 1)
        recordHttpError(resource: .mySegments, factor: 2)
        recordHttpError(resource: .impressions, factor: 3)
        recordHttpError(resource: .impressionsCount, factor: 4)
        recordHttpError(resource: .telemetry, factor: 5)
        recordHttpError(resource: .token, factor: 6)
        recordHttpError(resource: .events, factor: 7)

        let httpErrors = storage.popHttpErrors()
        let httpErrorsPop = storage.popHttpErrors()

        recordHttpError(resource: .splits, factor: 1)

        let httpErrorsNew = storage.popHttpErrors()

        XCTAssertEqual(1, httpErrors.splits?[400] ?? 0)
        XCTAssertEqual(1, httpErrors.splits?[401] ?? 0)
        XCTAssertEqual(1, httpErrors.splits?[402] ?? 0)

        XCTAssertEqual(2, httpErrors.mySegments?[400] ?? 0)
        XCTAssertEqual(2, httpErrors.mySegments?[401] ?? 0)
        XCTAssertEqual(2, httpErrors.mySegments?[402] ?? 0)

        XCTAssertEqual(3, httpErrors.impressions?[400] ?? 0)
        XCTAssertEqual(3, httpErrors.impressions?[401] ?? 0)
        XCTAssertEqual(3, httpErrors.impressions?[402] ?? 0)

        XCTAssertEqual(4, httpErrors.impressionsCount?[400] ?? 0)
        XCTAssertEqual(4, httpErrors.impressionsCount?[401] ?? 0)
        XCTAssertEqual(4, httpErrors.impressionsCount?[402] ?? 0)

        XCTAssertEqual(5, httpErrors.telemetry?[400] ?? 0)
        XCTAssertEqual(5, httpErrors.telemetry?[401] ?? 0)
        XCTAssertEqual(5, httpErrors.telemetry?[402] ?? 0)

        XCTAssertEqual(6, httpErrors.token?[400] ?? 0)
        XCTAssertEqual(6, httpErrors.token?[401] ?? 0)
        XCTAssertEqual(6, httpErrors.token?[402] ?? 0)

        XCTAssertEqual(7, httpErrors.events?[400] ?? 0)
        XCTAssertEqual(7, httpErrors.events?[401] ?? 0)
        XCTAssertEqual(7, httpErrors.events?[402] ?? 0)

        XCTAssertEqual(0, httpErrorsPop.splits?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.mySegments?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.impressions?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.impressionsCount?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.events?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.telemetry?.count ?? 0)
        XCTAssertEqual(0, httpErrorsPop.token?.count ?? 0)

        XCTAssertEqual(3, httpErrorsNew.splits?.count ?? 0)
    }

    func testHttpLatencies() {
        recordHttpLatency(resource: .splits, count: 3)
        recordHttpLatency(resource: .mySegments, count: 2)
        recordHttpLatency(resource: .impressions, count: 4)
        recordHttpLatency(resource: .impressionsCount, count: 9)
        recordHttpLatency(resource: .events, count: 3)
        recordHttpLatency(resource: .telemetry, count: 2)

        let latencies = storage.popHttpLatencies()
        let emptyPopLatencies = storage.popHttpLatencies()

        recordHttpLatency(resource: .token, count: 1)

        let newPopLatencies = storage.popHttpLatencies()

        XCTAssertEqual(3, sum(latencies.splits))
        XCTAssertEqual(2, sum(latencies.mySegments))
        XCTAssertEqual(4, sum(latencies.impressions))
        XCTAssertEqual(9, sum(latencies.impressionsCount))
        XCTAssertEqual(3, sum(latencies.events))
        XCTAssertEqual(2, sum(latencies.telemetry))
        XCTAssertEqual(0, sum(latencies.token))

        XCTAssertEqual(0, sum(emptyPopLatencies.splits))
        XCTAssertEqual(0, sum(emptyPopLatencies.mySegments))
        XCTAssertEqual(0, sum(emptyPopLatencies.impressions))
        XCTAssertEqual(0, sum(emptyPopLatencies.impressionsCount))
        XCTAssertEqual(0, sum(emptyPopLatencies.events))
        XCTAssertEqual(0, sum(emptyPopLatencies.telemetry))
        XCTAssertEqual(0, sum(emptyPopLatencies.events))

        XCTAssertEqual(1, sum(newPopLatencies.token))
    }

    func testAuthRejections() {
        for _ in 0 ..< 10 {
            storage.recordAuthRejections()
        }
        let count = storage.popAuthRejections()
        let countPop = storage.popAuthRejections()
        storage.recordAuthRejections()
        let newCount = storage.popAuthRejections()

        XCTAssertEqual(10, count)
        XCTAssertEqual(0, countPop)
        XCTAssertEqual(1, newCount)
    }

    func testTokenRefreshes() {
        for _ in 0 ..< 10 {
            storage.recordTokenRefreshes()
        }
        let count = storage.popTokenRefreshes()
        let countPop = storage.popTokenRefreshes()
        storage.recordTokenRefreshes()
        let newCount = storage.popTokenRefreshes()

        XCTAssertEqual(10, count)
        XCTAssertEqual(0, countPop)
        XCTAssertEqual(1, newCount)
    }

    func testStreamingEvents() {
        recordStreamingEvent(type: .ablyError, data: 4, count: 3)
        recordStreamingEvent(
            type: .streamingStatus,
            data: TelemetryStreamingEventValue.streamingDisabled,
            count: 2)
        recordStreamingEvent(
            type: .streamingStatus,
            data: TelemetryStreamingEventValue.streamingEnabled,
            count: 2)

        recordStreamingEvent(
            type: .ablyError,
            data: 2000,
            count: 10)
        recordStreamingEvent(
            type: .occupancyPri,
            data: 3,
            count: 1)
        recordStreamingEvent(
            type: .occupancySec,
            data: 1,
            count: 1)

        let events = storage.popStreamingEvents()
        let eventsPop = storage.popStreamingEvents()

        recordStreamingEvent(
            type: .ablyError,
            data: 2000,
            count: 40)

        let eventsNew = storage.popStreamingEvents()

        XCTAssertEqual(19, events.count)
        XCTAssertEqual(0, eventsPop.count)
        XCTAssertEqual(20, eventsNew.count)
    }

    func testTags() {
        addTags(prefix: "t1", count: 8)
        let tags = storage.popTags()
        let tagsPop = storage.popTags()
        addTags(prefix: "t2", count: 20) // Should only add max capacity
        let tagsMax = storage.popTags()

        XCTAssertEqual(8, tags.count)
        XCTAssertEqual(0, tagsPop.count)
        XCTAssertEqual(InMemoryTelemetryStorage.kMaxTagsCount, tagsMax.count)
    }

    func testSessionLength() {
        let initLength = storage.getSessionLength()
        storage.recordSessionLength(sessionLength: 1000)
        storage.recordSessionLength(sessionLength: 2000)
        let length = storage.getSessionLength()

        XCTAssertEqual(0, initLength)
        XCTAssertEqual(2000, length)
    }

    func testActiveFactoriesCount() {
        let initCount = storage.getActiveFactories()
        storage.recordFactories(active: 3, redundant: 0)
        let count = storage.getActiveFactories()

        XCTAssertEqual(0, initCount)
        XCTAssertEqual(3, count)
    }

    func testRedundantFactoriesCount() {
        let initCount = storage.getRedundantFactories()
        storage.recordFactories(active: 0, redundant: 2)
        storage.recordFactories(active: 0, redundant: 3)
        let count = storage.getRedundantFactories()

        XCTAssertEqual(0, initCount)
        XCTAssertEqual(3, count)
    }

    func testTimeUntilReady() {
        let initLength = storage.getTimeUntilReady()
        storage.recordTimeUntilReady(1000)
        storage.recordTimeUntilReady(2000)
        let length = storage.getTimeUntilReady()

        XCTAssertEqual(0, initLength)
        XCTAssertEqual(2000, length)
    }

    func testTimeUntilReadyFromCache() {
        let initLength = storage.getTimeUntilReadyFromCache()
        storage.recordTimeUntilReadyFromCache(1000)
        storage.recordTimeUntilReadyFromCache(2000)
        let length = storage.getTimeUntilReadyFromCache()

        XCTAssertEqual(0, initLength)
        XCTAssertEqual(2000, length)
    }

    func testUpdatesFromSse() {
        for i in 0 ..< 10 {
            storage.recordUpdatesFromSse(type: .splits)
            if (i % 2) == 0 {
                storage.recordUpdatesFromSse(type: .mySegments)
            }
        }
        let count = storage.popUpdatesFromSse()
        let afterCount = storage.popUpdatesFromSse()

        XCTAssertEqual(10, count.splits)
        XCTAssertEqual(5, count.mySegments)
        XCTAssertEqual(0, afterCount.splits)
        XCTAssertEqual(0, afterCount.mySegments)
    }

    func testConcurrence() {
        let queue = DispatchQueue(label: "concurrent-test", attributes: .concurrent)
        let group = DispatchGroup()
        let count = AtomicInt(0)
        for _ in 0 ..< 50 {
            group.enter()
            queue.async {
                self.storage.recordLatency(method: .track, latency: 1)
                self.storage.recordException(method: .treatment)
                self.storage.recordHttpError(resource: .events, status: 1)
                self.storage.recordHttpLatency(resource: .impressions, latency: 1)

                _ = self.storage.popMethodLatencies()
                _ = self.storage.popMethodExceptions()
                _ = self.storage.popHttpErrors()
                _ = self.storage.popHttpLatencies()
                _ = self.storage.popAuthRejections()
                _ = self.storage.popTokenRefreshes()
                _ = self.storage.popStreamingEvents()
                _ = count.addAndGet(1)
                group.leave()
            }

            group.enter()
            queue.async {
                self.storage.recordAuthRejections()
                self.storage.recordTokenRefreshes()
                self.storage.recordStreamingEvent(type: .ablyError, data: 3)
                self.storage.recordUpdatesFromSse(type: .mySegments)

                _ = self.storage.popMethodLatencies()
                _ = self.storage.popMethodExceptions()
                _ = self.storage.popHttpLatencies()
                _ = self.storage.popAuthRejections()
                _ = self.storage.popTokenRefreshes()
                _ = self.storage.popUpdatesFromSse()
                _ = count.addAndGet(1)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertEqual(100, count.value)
        }
    }

    private func recordStreamingEvent(
        type: TelemetryStreamingEventType,
        data: Int64,
        count: Int) {
        for _ in 0 ..< count {
            storage.recordStreamingEvent(type: type, data: data)
        }
    }

    private func addTags(prefix: String, count: Int) {
        for i in 0 ..< count {
            storage.addTag(tag: "\(prefix)\(i)")
        }
    }

    private func recordHttpError(resource: Resource, factor: Int) {
        for _ in 0 ..< factor {
            storage.recordHttpError(resource: resource, status: 400)
            storage.recordHttpError(resource: resource, status: 401)
            storage.recordHttpError(resource: resource, status: 402)
        }
    }

    private func recordLatency(method: TelemetryMethod, count: Int) {
        for _ in 0 ..< count {
            storage.recordLatency(method: method, latency: rnd)
        }
    }

    private func recordHttpLatency(resource: Resource, count: Int) {
        for _ in 0 ..< count {
            storage.recordHttpLatency(resource: resource, latency: rnd)
        }
    }

    private func recordException(method: TelemetryMethod, count: Int) {
        for _ in 0 ..< count {
            storage.recordException(method: method)
        }
    }

    private func recordImpression(type: TelemetryImpressionsDataType, countStat: Int, count: Int) {
        for _ in 0 ..< count {
            storage.recordImpressionStats(type: type, count: countStat)
        }
    }

    private func recordEvent(type: TelemetryEventsDataType, countStat: Int, count: Int) {
        for _ in 0 ..< count {
            storage.recordEventStats(type: type, count: countStat)
        }
    }

    private func sum(_ values: [Int]?) -> Int {
        return values?.reduce(0) { $0 + $1 } ?? -1
    }
}

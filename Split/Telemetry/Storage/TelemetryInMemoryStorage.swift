//
//  TelemetryInMemoryStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 03-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class InMemoryTelemetryStorage: TelemetryStorage {
    private static let kQueuePrefix = "split-telemetry"
    private let queue = DispatchQueue(label: "split-telemetry")

    // Latencies
    private var methodLatencies: [TelemetryMethod: LatencyCounter] = [:]
    private var httpLatencies: [Resource: LatencyCounter] = [:]
    private var httpErrors: [Resource: [Int: Int]] = [:]
    private var syncLatencies: [Resource: LatencyCounter] = [:]

    // Counters
    private var methodExceptionCounters: [TelemetryMethod: Int] = [:]
    private let nonReadyCounter: AtomicInt = .init(0)
    private let authRejections: AtomicInt = .init(0)
    private let tokenRefreshes: AtomicInt = .init(0)
    private let sessionLength: Atomic<Int64> = Atomic(0)

    private let activeFactoriesCounter: AtomicInt = .init(0)
    private let redundantFactoriesCounter: AtomicInt = .init(0)
    private let timeUntilReady: Atomic<Int64> = Atomic(0)
    private let timeUntilReadyFromCache: Atomic<Int64> = Atomic(0)

    // Records
    private var impressionsStats: [TelemetryImpressionsDataType: Int] = [:]
    private var eventsStats: [TelemetryEventsDataType: Int] = [:]
    private let lastSyncStats: ConcurrentDictionary<Resource, Int64> = ConcurrentDictionary()
    private var updatesFromSse: [TelemetryUpdatesFromSseType: Int] = [:]

    private let totalFlagSets: AtomicInt = .init(0)
    private let invalidFlagSets: AtomicInt = .init(0)

    // Streaming events
    static let kMaxStreamingEventsCount: Int = 20 // Visible for testing
    private let streamingEvents: SynchronizedList<TelemetryStreamingEvent> =
        SynchronizedList(capacity: kMaxStreamingEventsCount)

    // Tags
    static let kMaxTagsCount = 10 // Visible for testing
    private let tags: ConcurrentSet<String> = ConcurrentSet(capacity: kMaxTagsCount)

    init() {
        for method in TelemetryMethod.allCases {
            methodLatencies[method] = LatencyCounter()
            methodExceptionCounters[method] = 0
        }

        for endpoint in Resource.allCases {
            httpLatencies[endpoint] = LatencyCounter()
        }
    }

    func recordNonReadyUsage() {
        _ = nonReadyCounter.addAndGet(1)
    }

    func recordLatency(method: TelemetryMethod, latency: Int64) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.methodLatencies[method]?.addLatency(microseconds: latency)
        }
    }

    func recordException(method: TelemetryMethod) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.methodExceptionCounters[method]? += 1
        }
    }

    func addTag(tag: String) {
        tags.insert(tag)
    }

    func recordImpressionStats(type: TelemetryImpressionsDataType, count: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.impressionsStats[type] = (self.impressionsStats[type] ?? 0) + count
        }
    }

    func recordEventStats(type: TelemetryEventsDataType, count: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.eventsStats[type] = (self.eventsStats[type] ?? 0) + count
        }
    }

    func recordLastSync(resource: Resource, time: Int64) {
        lastSyncStats.setValue(time, forKey: resource)
    }

    func recordHttpError(resource: Resource, status: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if self.httpErrors[resource] == nil {
                self.httpErrors[resource] = [status: 1]
            } else {
                let newCount = (self.httpErrors[resource]?[status] ?? 0) + 1
                self.httpErrors[resource]?[status] = newCount
            }
        }
    }

    func recordHttpLatency(resource: Resource, latency: Int64) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.httpLatencies[resource]?.addLatency(microseconds: latency)
        }
    }

    func recordAuthRejections() {
        _ = authRejections.addAndGet(1)
    }

    func recordTokenRefreshes() {
        _ = tokenRefreshes.addAndGet(1)
    }

    func recordStreamingEvent(type: TelemetryStreamingEventType, data: Int64?) {
        streamingEvents.append(TelemetryStreamingEvent(
            type: type.rawValue,
            data: data,
            timestamp: Date().unixTimestampInMiliseconds()))
    }

    func recordSessionLength(sessionLength: Int64) {
        self.sessionLength.set(sessionLength)
    }

    func recordUpdatesFromSse(type: TelemetryUpdatesFromSseType) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.updatesFromSse[type] = (self.updatesFromSse[type] ?? 0) + 1
        }
    }

    func recordTotalFlagSets(_ value: Int) {
        totalFlagSets.set(value)
    }

    func recordInvalidFlagSets(_ value: Int) {
        invalidFlagSets.set(value)
    }

    func getNonReadyUsages() -> Int {
        return nonReadyCounter.value
    }

    func popMethodExceptions() -> TelemetryMethodExceptions {
        queue.sync {
            TelemetryMethodExceptions(
                treatment: popException(method: .treatment),
                treatments: popException(method: .treatments),
                treatmentWithConfig: popException(method: .treatmentWithConfig),
                treatmentsWithConfig: popException(method: .treatmentsWithConfig),
                track: popException(method: .track))
        }
    }

    func popMethodLatencies() -> TelemetryMethodLatencies {
        queue.sync {
            TelemetryMethodLatencies(
                treatment: popLatencies(method: .treatment),
                treatments: popLatencies(method: .treatments),
                treatmentWithConfig: popLatencies(method: .treatmentWithConfig),
                treatmentsWithConfig: popLatencies(method: .treatmentsWithConfig),
                treatmentsByFlagSet: popLatencies(method: .treatmentsByFlagSet),
                treatmentsByFlagSets: popLatencies(method: .treatmentsByFlagSets),
                treatmentsWithConfigByFlagSet:
                popLatencies(method: .treatmentsWithConfigByFlagSet),
                treatmentsWithConfigByFlagSets:
                popLatencies(method: .treatmentsWithConfigByFlagSets),
                track: popLatencies(method: .track))
        }
    }

    func getImpressionStats(type: TelemetryImpressionsDataType) -> Int {
        queue.sync {
            impressionsStats[type] ?? 0
        }
    }

    func getEventStats(type: TelemetryEventsDataType) -> Int {
        queue.sync {
            eventsStats[type] ?? 0
        }
    }

    func getLastSync() -> TelemetryLastSync {
        let syncValues = lastSyncStats.all
        return TelemetryLastSync(
            splits: syncValues[.splits],
            impressions: syncValues[.impressions],
            impressionsCount: syncValues[.impressionsCount],
            events: syncValues[.events],
            token: syncValues[.token],
            telemetry: syncValues[.telemetry],
            mySegments: syncValues[.mySegments])
    }

    func popHttpErrors() -> TelemetryHttpErrors {
        queue.sync {
            TelemetryHttpErrors(
                splits: popErrors(resource: .splits),
                mySegments: popErrors(resource: .mySegments),
                impressions: popErrors(resource: .impressions),
                impressionsCount: popErrors(resource: .impressionsCount),
                events: popErrors(resource: .events),
                token: popErrors(resource: .token),
                telemetry: popErrors(resource: .telemetry))
        }
    }

    func popHttpLatencies() -> TelemetryHttpLatencies {
        queue.sync {
            TelemetryHttpLatencies(
                splits: popLatencies(resource: .splits),
                mySegments: popLatencies(resource: .mySegments),
                impressions: popLatencies(resource: .impressions),
                impressionsCount: popLatencies(resource: .impressionsCount),
                events: popLatencies(resource: .events),
                token: popLatencies(resource: .token),
                telemetry: popLatencies(resource: .telemetry))
        }
    }

    func popAuthRejections() -> Int {
        return authRejections.getAndSet(0)
    }

    func popTokenRefreshes() -> Int {
        return tokenRefreshes.getAndSet(0)
    }

    func popStreamingEvents() -> [TelemetryStreamingEvent] {
        return streamingEvents.takeAll()
    }

    func popTags() -> [String] {
        return Array(tags.takeAll())
    }

    func popUpdatesFromSse() -> TelemetryUpdatesFromSse {
        queue.sync {
            let splitsCount = self.updatesFromSse[.splits] ?? 0
            let mySegmentsCount = self.updatesFromSse[.mySegments] ?? 0
            self.updatesFromSse.removeAll()
            return TelemetryUpdatesFromSse(splits: splitsCount, mySegments: mySegmentsCount)
        }
    }

    func getSessionLength() -> Int64 {
        return sessionLength.value
    }

    func recordFactories(active: Int, redundant: Int) {
        activeFactoriesCounter.set(active)
        redundantFactoriesCounter.set(redundant)
    }

    func recordTimeUntilReady(_ time: Int64) {
        timeUntilReady.set(time)
    }

    func recordTimeUntilReadyFromCache(_ time: Int64) {
        timeUntilReadyFromCache.set(time)
    }

    func getActiveFactories() -> Int {
        return activeFactoriesCounter.value
    }

    func getRedundantFactories() -> Int {
        return redundantFactoriesCounter.value
    }

    func getTimeUntilReady() -> Int64 {
        return timeUntilReady.value
    }

    func getTimeUntilReadyFromCache() -> Int64 {
        return timeUntilReadyFromCache.value
    }

    func getTotalFlagSets() -> Int {
        return totalFlagSets.value
    }

    func getInvalidFlagSets() -> Int {
        return invalidFlagSets.value
    }

    // MARK: Private methods

    //
    // IMPORTANT!!
    // Use this method within a serial queue to avoid concurrency issues
    //
    private func popLatencies(method: TelemetryMethod) -> [Int]? {
        let counters = methodLatencies[method]?.allCounters
        methodLatencies[method]?.resetCounters()
        return counters
    }

    private func popLatencies(resource: Resource) -> [Int]? {
        let counters = httpLatencies[resource]?.allCounters
        httpLatencies[resource]?.resetCounters()
        return counters
    }

    private func popException(method: TelemetryMethod) -> Int? {
        return methodExceptionCounters.removeValue(forKey: method)
    }

    private func popErrors(resource: Resource) -> [Int: Int]? {
        return httpErrors.removeValue(forKey: resource)
    }
}

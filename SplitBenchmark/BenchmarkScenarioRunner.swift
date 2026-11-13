//
//  BenchmarkScenarioRunner.swift
//  SplitBenchmark
//
//  FME-22007: runs ONE scenario against a `BenchmarkDriver` and returns one CSV row per factory. Contains no
//  XCTest and no real-SDK code: the driver supplies the factories, the clock and the cache.
//
//  Rules (spec 6.3):
//  - T0 is the driver clock read immediately before build(); T11 is the driver clock read inside the
//    ready-from-cache callback closure. The clock is read for nothing else (a unit test pins this).
//  - Each factory is built by its own build() call of the driver, which owns one builder per factory.
//  - A single, B, E, D, stress: build 1, wait for its ready callback when another build follows (B, E), build 2.
//    C and C2: both builds back to back from the calling thread. C-bg: both builds from two background
//    queues released by a barrier. Ordering is decided by this class's event sequence, never by time.
//  - Cache: D deletes database and cache before the measured build and does not populate. Every other
//    scenario makes sure the cache of each key holds the payload BEFORE T0 (`prepareCache`), and records
//    whether it had to populate it in this process (`populatedThisRun`), because a same-process populate warms
//    the CoreData stack and file cache compared to a relaunch.
//  - Per-factory stage marks come from that factory's own mark buffer (the driver), which also gives
//    per-factory database timing attribution. [SPTPRF] log lines are not used: they carry one fixed tag.
//  - Randomised blocks, warm-up and idle-gap pacing belong to the driver of the whole run (issue 30); the
//    runner only records the idle gap argument.
//

import Foundation

enum BenchmarkRunnerError: Error, Equatable {
    case buildFailed(position: Int)
    case readyTimeout(position: Int)
}

final class BenchmarkScenarioRunner {

    static let apiKeyA = "benchkey-alpha-0000a1b2"
    static let apiKeyB = "benchkey-beta-00000c3d"
    private static let identityA = "keyA"
    private static let identityB = "keyB"
    private static let t8Mark = "T8 splitsLoadedFromCache notified"

    private enum Mode {
        case sequential // build n+1 starts after ready n (single factory, B, E)
        case backToBack // C, C2
        case backgroundBarrier // C-bg
    }

    /// Mutable state of one factory, shared with the ready callback closure.
    private final class Record: @unchecked Sendable {
        private let lock = NSLock()
        private var t0Value: UInt64 = 0
        private var t11Value: UInt64 = 0
        private var readyValue = false
        private var returnedValue = false
        private var failedValue = false

        var t0: UInt64 { lock.lock(); defer { lock.unlock() }; return t0Value }
        var t11: UInt64 { lock.lock(); defer { lock.unlock() }; return t11Value }
        var isReady: Bool { lock.lock(); defer { lock.unlock() }; return readyValue }
        var hasReturned: Bool { lock.lock(); defer { lock.unlock() }; return returnedValue }
        var failed: Bool { lock.lock(); defer { lock.unlock() }; return failedValue }

        func setT0(_ value: UInt64) { lock.lock(); t0Value = value; lock.unlock() }
        func markReturned(failed: Bool) { lock.lock(); returnedValue = true; failedValue = failed; lock.unlock() }
        /// Records the first firing only.
        func fire(t11 value: UInt64) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if readyValue { return false }
            t11Value = value
            readyValue = true
            return true
        }
    }

    private let arguments: BenchmarkArguments
    private let driver: BenchmarkDriver
    private let payload: BenchmarkPayload
    private let readyTimeout: TimeInterval
    private let keys: (a: String, b: String)
    private let eventLock = NSLock()
    private var recordedEvents = [String]()

    /// The ordered sequence of runner events: prepare, delete, build start/return (with thread), ready.
    var events: [String] {
        eventLock.lock()
        defer { eventLock.unlock() }
        return recordedEvents
    }

    /// `apiKeys` replaces the two fixed benchmark keys; a test that must not share a store with an earlier
    /// scenario in the same process passes unique ones.
    init(arguments: BenchmarkArguments, driver: BenchmarkDriver, payload: BenchmarkPayload,
         readyTimeout: TimeInterval = 60, apiKeys: (a: String, b: String) = (apiKeyA, apiKeyB)) {
        self.keys = apiKeys
        self.arguments = arguments
        self.driver = driver
        self.payload = payload
        self.readyTimeout = readyTimeout
    }

    private func log(_ event: String) {
        eventLock.lock()
        recordedEvents.append(event)
        eventLock.unlock()
    }

    private func plan() -> (mode: Mode, specs: [BenchmarkFactorySpec]) {
        func spec(_ position: Int, _ identity: String) -> BenchmarkFactorySpec {
            let key = identity == Self.identityA ? keys.a : keys.b
            return BenchmarkFactorySpec(position: position, apiKeyIdentity: identity, apiKey: key,
                                        matchingKey: "bench_user_\(position)")
        }
        switch arguments.scenario {
        case .a, .d, .stress2x, .stress4x:
            return (.sequential, [spec(1, Self.identityA)])
        case .b:
            return (.sequential, [spec(1, Self.identityA), spec(2, Self.identityB)])
        case .e:
            return (.sequential, [spec(1, Self.identityB), spec(2, Self.identityA)])
        case .c:
            return (.backToBack, [spec(1, Self.identityA), spec(2, Self.identityA)])
        case .c2:
            return (.backToBack, [spec(1, Self.identityA), spec(2, Self.identityB)])
        case .cBackground:
            return (.backgroundBarrier, [spec(1, Self.identityA), spec(2, Self.identityA)])
        }
    }

    func run() throws -> [BenchmarkCSVRow] {
        let (mode, specs) = plan()
        defer { driver.shutdown() }
        let wallClockStart = driver.wallClock()

        var deleted = false
        var populated = false
        var seenKeys = [String]()
        for spec in specs where !seenKeys.contains(spec.apiKey) {
            seenKeys.append(spec.apiKey)
            if arguments.scenario == .d {
                driver.deleteCache(apiKey: spec.apiKey)
                deleted = true
                log("delete:\(spec.apiKeyIdentity)")
            } else {
                let didPopulate = try driver.prepareCache(apiKey: spec.apiKey)
                populated = populated || didPopulate
                log("prepare:\(spec.apiKeyIdentity):\(didPopulate ? "populated" : "present")")
            }
        }

        let thermalBefore = driver.thermalState()
        log("thermal:before")
        let records = specs.map { _ in Record() }

        switch mode {
        case .sequential:
            for (index, spec) in specs.enumerated() {
                try buildOne(spec, record: records[index])
                if index < specs.count - 1 { try awaitReady(spec.position, records[index]) }
            }
        case .backToBack:
            for (index, spec) in specs.enumerated() { try buildOne(spec, record: records[index]) }
        case .backgroundBarrier:
            try buildBehindBarrier(specs, records)
        }
        for (index, spec) in specs.enumerated() { try awaitReady(spec.position, records[index]) }

        let thermalAfter = driver.thermalState()
        log("thermal:after")
        return makeRows(specs, records, thermalBefore, thermalAfter, wallClockStart,
                        deleted: deleted, populated: populated)
    }

    private func buildOne(_ spec: BenchmarkFactorySpec, record: Record) throws {
        log("build:\(spec.position):start:\(Thread.isMainThread ? "main" : "bg")")
        let driver = self.driver
        let position = spec.position
        let t0 = driver.now()
        record.setT0(t0)
        let built = driver.build(spec, readyAPI: arguments.readyAPI) { [weak self] in
            let t11 = driver.now()
            if record.fire(t11: t11) { self?.log("ready:\(position)") }
        }
        record.markReturned(failed: !built)
        log("build:\(position):return")
        if !built { throw BenchmarkRunnerError.buildFailed(position: position) }
    }

    private func buildBehindBarrier(_ specs: [BenchmarkFactorySpec], _ records: [Record]) throws {
        let arrived = Counter()
        let released = Counter()
        let gate = DispatchSemaphore(value: 0)
        for (index, spec) in specs.enumerated() {
            let queue = DispatchQueue(label: "benchmark.cbg.\(spec.position)", qos: .userInteractive)
            queue.async { [self] in
                arrived.increment()
                gate.wait()
                try? buildOne(spec, record: records[index])
                released.increment()
            }
        }
        guard driver.waitUntil(timeout: readyTimeout, { arrived.value == specs.count }) else {
            throw BenchmarkRunnerError.buildFailed(position: 0)
        }
        log("barrier:released")
        for _ in specs { gate.signal() }
        guard driver.waitUntil(timeout: readyTimeout, { released.value == specs.count }) else {
            throw BenchmarkRunnerError.buildFailed(position: 0)
        }
        if let failed = records.firstIndex(where: { $0.failed }) {
            throw BenchmarkRunnerError.buildFailed(position: specs[failed].position)
        }
    }

    private func awaitReady(_ position: Int, _ record: Record) throws {
        guard driver.waitUntil(timeout: readyTimeout, { record.isReady }) else {
            throw BenchmarkRunnerError.readyTimeout(position: position)
        }
    }

    private func makeRows(_ specs: [BenchmarkFactorySpec], _ records: [Record],
                          _ thermalBefore: ProcessInfo.ThermalState, _ thermalAfter: ProcessInfo.ThermalState,
                          _ wallClockStart: Date, deleted: Bool, populated: Bool) -> [BenchmarkCSVRow] {
        var bothReady = ""
        if specs.count > 1, let earliest = records.map({ $0.t0 }).min(), let latest = records.map({ $0.t11 }).max() {
            bothReady = String(latest &- earliest)
        }
        return specs.enumerated().map { index, spec in
            let record = records[index]
            let marks = driver.marks(position: spec.position)
            var t8ToFire = ""
            if let t8 = marks.first(where: { $0.name == Self.t8Mark }) {
                t8ToFire = String(Int64(bitPattern: record.t11 &- t8.nanos))
            }
            let extras = BenchmarkRowExtras(factoryIndex: String(spec.position), apiKeyIdentity: spec.apiKeyIdentity,
                                            bothReadyNs: bothReady, t8ToFireNs: t8ToFire,
                                            deletedBeforeMeasure: deleted ? "true" : "false",
                                            populatedThisRun: populated ? "true" : "false",
                                            payloadMultiplier: String(payload.multiplier))
            return BenchmarkCSVRow(arguments: arguments, fixtureSeed: payload.seed, fixtureHash: payload.hash,
                                   t0: record.t0, t11: record.t11, marks: marks, thermalBefore: thermalBefore,
                                   thermalAfter: thermalAfter, wallClockStart: wallClockStart, extras: extras)
        }
    }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    func increment() { lock.lock(); count += 1; lock.unlock() }
}

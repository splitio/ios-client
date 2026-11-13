//
//  BenchmarkDriver.swift
//  SplitBenchmark
//
//  FME-22007: everything the scenario runner needs from the outside world, behind one protocol so unit tests
//  drive the runner with fakes and assert on a recorded event sequence instead of on time.
//

import Foundation

/// One factory the runner builds. `position` is the build order (1 = build() started first).
struct BenchmarkFactorySpec: Equatable {
    let position: Int
    let apiKeyIdentity: String
    let apiKey: String
    let matchingKey: String
}

/// The fixture a run reads its cache from, with the aggregates the CSV records.
struct BenchmarkPayload: Equatable {
    let fileURL: URL
    let seed: UInt64
    let hash: String
    let multiplier: Int
}

protocol BenchmarkDriver: AnyObject {
    /// Monotonic uptime in nanoseconds.
    func now() -> UInt64
    func thermalState() -> ProcessInfo.ThermalState
    func wallClock() -> Date
    /// Makes sure the on-disk cache of this API key holds the payload. True when it had to be populated now.
    func prepareCache(apiKey: String) throws -> Bool
    /// Removes the database and cache of this API key.
    func deleteCache(apiKey: String)
    /// Builds a factory with a builder used for this factory only. `onReadyFromCache` is the ready callback
    /// of the run's pinned API; the driver registers it before returning. False when no factory came back.
    func build(_ spec: BenchmarkFactorySpec, readyAPI: ReadyAPI,
               onReadyFromCache: @escaping @Sendable () -> Void) -> Bool
    /// Stage marks recorded by the factory built at this position.
    func marks(position: Int) -> [BenchmarkCSVRow.Mark]
    /// Waits until `condition` holds, keeping the main run loop serviced. False on timeout.
    func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool
    func shutdown()
}

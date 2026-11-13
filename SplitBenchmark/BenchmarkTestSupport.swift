//
//  BenchmarkTestSupport.swift
//  SplitBenchmark
//
//  Test-only fake driver. Ordering is observed through the runner's recorded event sequence; the fake
//  provokes interleavings (a delayed ready callback, a build that waits for its peer) so a wrongly ordered
//  runner shows in the sequence, and never relies on elapsed time for a correct runner to pass.
//

import Foundation
import Network
@testable import Split

final class FakeBenchmarkDriver: BenchmarkDriver, @unchecked Sendable {
    enum ReadyMode {
        case immediate
        /// Fires the callback from a background queue after this delay.
        case delayed(TimeInterval)
        /// Never fires; the test fires through `fire(position:)`.
        case manual
    }

    private let lock = NSLock()
    private var clock: UInt64 = 1_000
    private var thermalReads = 0
    private var started = Set<Int>()
    private var callbacks = [Int: @Sendable () -> Void]()

    var readyMode = ReadyMode.immediate
    /// Thermal states returned by successive reads; the last one repeats.
    var thermal: [ProcessInfo.ThermalState] = [.nominal]
    /// Keys whose cache is already populated.
    var cachedKeys = Set<String>()
    var failBuildAtPosition: Int?
    /// Build positions that wait (bounded) for the other factory's build to have started.
    var waitForPeer = Set<Int>()
    var marksByPosition = [Int: [BenchmarkCSVRow.Mark]]()

    private(set) var specs = [BenchmarkFactorySpec]()
    private(set) var readyAPIs = [ReadyAPI]()
    private(set) var peerStartedWhileInBuild = [Int: Bool]()
    private(set) var preparedKeys = [String]()
    private(set) var deletedKeys = [String]()
    private(set) var shutdownCalls = 0
    var thermalReadCount: Int { lock.lock(); defer { lock.unlock() }; return thermalReads }

    func now() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        clock += 10
        return clock
    }

    func thermalState() -> ProcessInfo.ThermalState {
        lock.lock()
        defer { lock.unlock() }
        let index = min(thermalReads, thermal.count - 1)
        thermalReads += 1
        return thermal[index]
    }

    func wallClock() -> Date { return Date(timeIntervalSince1970: 1_700_000_000) }

    func prepareCache(apiKey: String) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        preparedKeys.append(apiKey)
        return cachedKeys.insert(apiKey).inserted
    }

    func deleteCache(apiKey: String) {
        lock.lock()
        deletedKeys.append(apiKey)
        cachedKeys.remove(apiKey)
        lock.unlock()
    }

    func build(_ spec: BenchmarkFactorySpec, readyAPI: ReadyAPI,
               onReadyFromCache: @escaping @Sendable () -> Void) -> Bool {
        lock.lock()
        specs.append(spec)
        readyAPIs.append(readyAPI)
        started.insert(spec.position)
        callbacks[spec.position] = onReadyFromCache
        let mustWait = waitForPeer.contains(spec.position)
        let failing = failBuildAtPosition == spec.position
        let mode = readyMode
        lock.unlock()

        if mustWait {
            let deadline = Date().addingTimeInterval(0.3)
            while Date() < deadline && peerStarted(than: spec.position) == false { Thread.sleep(forTimeInterval: 0.002) }
            lock.lock()
            peerStartedWhileInBuild[spec.position] = peerStarted(than: spec.position, locked: true)
            lock.unlock()
        }
        if failing { return false }
        switch mode {
        case .immediate: onReadyFromCache()
        case .delayed(let delay):
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { onReadyFromCache() }
        case .manual: break
        }
        return true
    }

    private func peerStarted(than position: Int, locked: Bool = false) -> Bool {
        if !locked { lock.lock() }
        defer { if !locked { lock.unlock() } }
        return started.contains { $0 != position }
    }

    func fire(position: Int) {
        lock.lock()
        let callback = callbacks[position]
        lock.unlock()
        callback?()
    }

    func marks(position: Int) -> [BenchmarkCSVRow.Mark] { return marksByPosition[position] ?? [] }

    func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline { return false }
            Thread.sleep(forTimeInterval: 0.001)
        }
        return true
    }

    func shutdown() { shutdownCalls += 1 }
}

enum BenchmarkTestFixtures {
    static func payload(multiplier: Int = 1) -> BenchmarkPayload {
        return BenchmarkPayload(fileURL: URL(fileURLWithPath: "/tmp/fixture.json"), seed: 22007,
                                hash: "feedface", multiplier: multiplier)
    }

    static func arguments(_ scenario: String, extra: [String] = []) throws -> BenchmarkArguments {
        return try BenchmarkArguments.parse(["-benchScenario", scenario, "-benchSHA", "abc"] + extra)
    }

    static func values(_ row: BenchmarkCSVRow) -> [String: String] {
        return Dictionary(uniqueKeysWithValues: zip(BenchmarkCSVRow.columns, row.fields))
    }
}

/// Loopback HTTP server answering every request with an empty rollout payload. Lets an empty cache reach
/// ready-from-cache (scenario D) without a network.
final class LoopbackStubServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "benchmark.stub.server")
    private let started = DispatchSemaphore(value: 0)

    init() throws { listener = try NWListener(using: .tcp, on: .any) }

    /// Base URL once listening.
    func start() -> String? {
        listener.stateUpdateHandler = { [started] state in if case .ready = state { started.signal() } }
        listener.newConnectionHandler = { [queue] connection in
            connection.start(queue: queue)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { _, _, _, _ in
                let body = #"{"ff":{"d":[],"s":-1,"t":-1},"rbs":{"d":[],"s":-1,"t":-1},"splits":[],"since":-1,"till":100,"ms":{"k":[],"cn":-1},"ls":{"k":[],"cn":-1}}"#
                let head = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
                connection.send(content: Data((head + body).utf8), completion: .contentProcessed { _ in connection.cancel() })
            }
        }
        listener.start(queue: queue)
        guard started.wait(timeout: .now() + 5) == .success, let port = listener.port else { return nil }
        return "http://127.0.0.1:\(port.rawValue)"
    }

    func stop() { listener.cancel() }
}

//
//  MultiFactoryTimeCheckerTest.swift
//  SplitTests
//
//  FME-20428: [SPTPRF] timings must be measured per factory.
//

import Foundation
import XCTest
@testable import Split

class MultiFactoryTimeCheckerTest: XCTestCase {

    private let gapMillis = 2000
    private var savedLevel: LogLevel!
    private var savedPrinter: LogPrinter!
    private var printerStub: LogPrinterStub!
    private var gate: DispatchSemaphore!
    private var gateHits: AtomicInt!
    private var clients = [SplitClient]()
    private let clientsLock = NSLock()

    override func setUp() {
        savedLevel = Logger.shared.level
        savedPrinter = Logger.shared.printer
        printerStub = LogPrinterStub()
        Logger.shared.level = .verbose
        Logger.shared.printer = printerStub
        gate = DispatchSemaphore(value: 0)
        gateHits = AtomicInt(0)
        clients = []
    }

    override func tearDown() {
        // Always open the gate so no general-queue thread stays blocked
        gate.signal()
        for client in clients {
            client.destroy()
        }
        clients = []
        Logger.shared.level = savedLevel
        Logger.shared.printer = savedPrinter
    }

    func testSdkReadyIntervalsAreMeasuredFromEachFactoryStart() {
        printerStub.clear()
        let testStart = Int(Date.nowMillis())

        // Only A's first splitChanges request is gated (one-shot)
        let readyA = XCTestExpectation(description: "A ready")
        let readyB = XCTestExpectation(description: "B ready")

        let beforeBuildA = Int(Date.nowMillis())
        let clientA = buildClient(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bc1", gated: true, ready: readyA)
        let afterBuildA = Int(Date.nowMillis())

        // Let A run alone for a while, then build B
        let wait = XCTestExpectation(description: "gap")
        wait.isInverted = true
        _ = XCTWaiter().wait(for: [wait], timeout: Double(gapMillis) / 1000.0)

        let beforeBuildB = Int(Date.nowMillis())
        let clientB = buildClient(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bc2", gated: false, ready: readyB)
        let afterBuildB = Int(Date.nowMillis())
        XCTAssertNotNil(clientA)
        XCTAssertNotNil(clientB)

        gate.signal() // open A's gate
        XCTAssertEqual(.completed, XCTWaiter().wait(for: [readyA, readyB], timeout: 15))

        // Only lines emitted during this test; exactly one per factory (one key each)
        let readyLines = lines(Self.readyMsg, since: testStart)
        XCTAssertEqual(readyLines.count, 2, "Expected exactly one SDK_READY line per factory: \(readyLines)")

        let minimum = Int(Double(gapMillis) * 0.8)
        let maxInterval = readyLines.map { $0.interval }.max() ?? 0
        XCTAssertGreaterThanOrEqual(maxInterval, minimum,
                                    "A's SDK_READY interval was measured from B's start: \(readyLines)")

        let ffLines = lines(Self.featureFlagsMsg, since: testStart)
        let segLines = lines(Self.segmentsMsg, since: testStart)
        XCTAssertEqual(ffLines.count, 2, "\(ffLines)")
        XCTAssertEqual(segLines.count, 2, "\(segLines)")
        guard ffLines.count == 2, segLines.count == 2, readyLines.count == 2,
              let rdA = readyLines.max(by: { $0.interval < $1.interval }),
              let rdB = readyLines.min(by: { $0.interval < $1.interval }),
              let tagA = rdA.tag, let tagB = rdB.tag,
              let ffA = ffLines.first(where: { $0.tag == tagA }),
              let ffB = ffLines.first(where: { $0.tag == tagB }) else {
            return XCTFail("Missing [F<id>] tags: \(ffLines)")
        }
        XCTAssertNotEqual(tagA, tagB, "Factories share a tag: \(ffLines)")

        // Per-key paths (events manager SDK_READY, segments from cache) must use the factory's tag
        let readyA_ = readyLines.filter { $0.tag == tagA }
        let readyB_ = readyLines.filter { $0.tag == tagB }
        XCTAssertEqual(readyA_.count, 1, "SDK_READY lines not tagged per factory: \(readyLines)")
        XCTAssertEqual(readyB_.count, 1, "SDK_READY lines not tagged per factory: \(readyLines)")
        let segA = segLines.filter { $0.tag == tagA }
        let segB = segLines.filter { $0.tag == tagB }
        XCTAssertEqual(segA.count, 1, "Segments-from-cache lines not tagged per factory: \(segLines)")
        XCTAssertEqual(segB.count, 1, "Segments-from-cache lines not tagged per factory: \(segLines)")
        guard let rA = readyA_.first, let rB = readyB_.first, let sA = segA.first, let sB = segB.first else { return }

        // Exactly two distinct tags across all three message types: no line may carry a third tag
        let allTags = Set((ffLines + readyLines + segLines).map { $0.tag ?? "-" })
        XCTAssertEqual(allTags, Set([tagA, tagB]), "Lines carry unexpected tags: \(allTags)")

        // A's SDK_READY waits for the gate: >= 1600 and clearly larger than B's
        XCTAssertGreaterThanOrEqual(rA.interval, minimum, "\(readyLines)")
        XCTAssertGreaterThan(rA.interval, rB.interval, "\(readyLines)")
        XCTAssertGreaterThanOrEqual(rA.interval - rB.interval, gapMillis - 800, "A-B gap too small: \(readyLines)")

        // Baseline (timestamp - interval) must be one value per factory, taken at the start of build()
        let slack = 100
        for (name, lines, before, after) in [("A", [ffA, rA, sA], beforeBuildA, afterBuildA),
                                              ("B", [ffB, rB, sB], beforeBuildB, afterBuildB)] {
            let baselines = lines.map { $0.timestamp - $0.interval }
            let spread = (baselines.max() ?? 0) - (baselines.min() ?? 0)
            XCTAssertLessThanOrEqual(spread, 20, "\(name) lines use different baselines: \(lines)")
            for base in baselines {
                XCTAssertGreaterThanOrEqual(base, before - 20, "\(name) baseline before build: \(lines)")
                XCTAssertLessThanOrEqual(base, min(after, before + slack),
                                         "\(name) start captured late: \(lines)")
            }
        }
        // Segments load from cache right after build (not gated): bounded by build duration
        XCTAssertGreaterThanOrEqual(sA.interval, 0, "\(segLines)")
        XCTAssertGreaterThanOrEqual(sB.interval, 0, "\(segLines)")
        XCTAssertLessThan(sA.interval, gapMillis / 2, "\(segLines)")
        XCTAssertLessThan(sB.interval, gapMillis / 2, "\(segLines)")
        XCTAssertLessThan(sA.interval, rA.interval, "\(segLines)")
    }

    // MARK: - Exactly once

    private final class FactorySlot {
        var client: SplitClient?
        let cacheCount = AtomicInt(0)
    }

    func test_twoFactories_readyFromCacheOncePerFactory() {
        printerStub.clear()
        let testStart = Int(Date.nowMillis())
        let mark = printerStub.logsSnapshot().count

        // Two factories, each with its own seeded cache, built concurrently in one process
        let apiKeys = ["99049fd8653247c5ea42bc3c1ae2c6a42bc6", "99049fd8653247c5ea42bc3c1ae2c6a42bc7"]
        let databases = [seededCacheDatabase(), seededCacheDatabase()]
        let slots = [FactorySlot(), FactorySlot()]
        DispatchQueue.concurrentPerform(iterations: 2) { index in
            slots[index].client = buildCachedClient(apiKey: apiKeys[index], database: databases[index])
        }
        guard let clientA = slots[0].client, let clientB = slots[1].client else {
            return XCTFail("Both factories must build")
        }

        let cacheA = XCTestExpectation(description: "A sdkReadyFromCache")
        let cacheB = XCTestExpectation(description: "B sdkReadyFromCache")
        let secondA = XCTestExpectation(description: "A second sdkReadyFromCache")
        secondA.isInverted = true
        let secondB = XCTestExpectation(description: "B second sdkReadyFromCache")
        secondB.isInverted = true
        let readyA = XCTestExpectation(description: "A ready")
        let readyB = XCTestExpectation(description: "B ready")

        observeCacheReady(clientA, count: slots[0].cacheCount, first: cacheA, second: secondA)
        observeCacheReady(clientB, count: slots[1].cacheCount, first: cacheB, second: secondB)
        clientA.on(event: SplitEvent.sdkReady) { readyA.fulfill() }
        clientB.on(event: SplitEvent.sdkReady) { readyB.fulfill() }

        XCTAssertEqual(.completed, XCTWaiter().wait(for: [cacheA, cacheB, readyA, readyB], timeout: 15))
        // No second sdkReadyFromCache may follow for either factory
        XCTAssertEqual(.completed, XCTWaiter().wait(for: [secondA, secondB], timeout: 0.5))

        XCTAssertEqual(slots[0].cacheCount.value, 1, "Factory A must fire sdkReadyFromCache exactly once")
        XCTAssertEqual(slots[1].cacheCount.value, 1, "Factory B must fire sdkReadyFromCache exactly once")

        // [SPTPRF] identity: the SDK_READY lines of this test carry two distinct [F<id>] tags, one per factory.
        // Other [SPTPRF] lines are not asserted here: database-level lines use the test database's own timeChecker.
        let readyLines = lines(Self.readyMsg, since: testStart)
        let readyTags = Set(readyLines.compactMap { $0.tag })
        XCTAssertEqual(readyLines.count, 2, "Expected exactly one SDK_READY line per factory: \(readyLines)")
        XCTAssertEqual(readyTags.count, 2, "SDK_READY lines must carry two distinct tags: \(readyLines)")

        let stage = stageLines(from: mark)
        for tag in readyTags {
            XCTAssertFalse(stage.filter { $0.tag == tag }.isEmpty,
                           "Factory tag \(tag) has no [SPTPRF] lines: \(stage.map { $0.line })")
        }
    }

    // MARK: - Helpers

    private struct StageLine {
        let index: Int
        let tag: String?
        let line: String
    }

    private func stageLines(from mark: Int) -> [StageLine] {
        let tagRegex = try! NSRegularExpression(pattern: #"\[F(\d+)\]"#)
        var result = [StageLine]()
        for (index, line) in printerStub.logsSnapshot().enumerated() where index >= mark && line.contains("[SPTPRF]") {
            result.append(StageLine(index: index, tag: firstMatch(tagRegex, line)?.first, line: line))
        }
        return result
    }

    private func destroyClients() {
        for client in clients {
            client.destroy()
        }
        clients = []
    }

    private static let readyMsg = "Running event on main: SDK_READY"
    private static let featureFlagsMsg = "Time until feature flags process ended"
    private static let segmentsMsg = "Time until my segments loaded from cache"

    private struct TimedLine: CustomStringConvertible {
        let tag: String?
        let timestamp: Int
        let interval: Int
        var description: String { "[F\(tag ?? "-")] at \(timestamp) \(interval) ms" }
    }

    private func firstMatch(_ regex: NSRegularExpression, _ line: String) -> [String]? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        var groups = [String]()
        for i in 1..<match.numberOfRanges {
            guard let r = Range(match.range(at: i), in: line) else { return nil }
            groups.append(String(line[r]))
        }
        return groups
    }

    /// Lines for `message` (not a prefix of SDK_READY_FROM_CACHE etc.) with `at <ts>` >= since.
    private func lines(_ message: String, since: Int) -> [TimedLine] {
        let regex = try! NSRegularExpression(
            pattern: NSRegularExpression.escapedPattern(for: message)
                + #"\s+at (\d+)\s+(-?\d+) ms since instanciation start"#)
        let tagRegex = try! NSRegularExpression(pattern: #"\[F(\d+)\]"#)
        var result = [TimedLine]()
        for line in printerStub.logsSnapshot() {
            if let m = firstMatch(regex, line), let ts = Int(m[0]), let iv = Int(m[1]), ts >= since {
                result.append(TimedLine(tag: firstMatch(tagRegex, line)?.first, timestamp: ts, interval: iv))
            }
        }
        return result
    }

    private func buildClient(apiKey: String, gated: Bool, ready: XCTestExpectation,
                             database: SplitDatabase? = nil, syncConfig: SyncConfig? = nil) -> SplitClient {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildDispatcher(gated: gated),
                                                          streamingHandler: { request in
            TestStreamResponseBinding.createFor(request: request, code: 200)
        })
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        let config = SplitClientConfig()
        config.serviceEndpoints = IntegrationHelper.mockServiceEndpoint
        config.streamingEnabled = false
        config.featuresRefreshRate = 9999
        config.segmentsRefreshRate = 9999
        config.impressionRefreshRate = 999999
        config.eventsPushRate = 999999
        config.sdkReadyTimeOut = 20000
        // Telemetry disabled: random sampling adds a second sdkReady subscription that duplicates the SDK_READY log line.
        config.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: false)
        if let syncConfig = syncConfig {
            config.sync = syncConfig
        }

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database ?? TestingHelper.createTestDatabase(name: UUID().uuidString))
        let factory = builder.setApiKey(apiKey)
            .setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
            .setConfig(config).build()!
        let client = factory.client
        clients.append(client)
        client.on(event: SplitEvent.sdkReady) { ready.fulfill() }
        return client
    }

    private func seededCacheDatabase() -> SplitDatabase {
        let database = TestingHelper.createTestDatabase(name: UUID().uuidString)
        database.splitDao.syncInsertOrUpdate(split: TestingHelper.buildSplit(name: "mf_split", treatment: "on"))
        database.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)
        database.generalInfoDao.update(info: .cacheIntegrityVersion,
                                       longValue: DefaultRolloutCacheManager.cacheIntegrityVersion)
        return database
    }

    private func observeCacheReady(_ client: SplitClient, count: AtomicInt,
                                   first: XCTestExpectation, second: XCTestExpectation) {
        client.on(event: SplitEvent.sdkReadyFromCache) {
            if count.getAndAdd(1) == 0 {
                first.fulfill()
            } else {
                second.fulfill()
            }
        }
    }

    /// Same config as buildClient, without registering any event. Safe to call from concurrent threads.
    private func buildCachedClient(apiKey: String, database: SplitDatabase) -> SplitClient {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildDispatcher(gated: false),
                                                          streamingHandler: { request in
            TestStreamResponseBinding.createFor(request: request, code: 200)
        })
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)

        let config = SplitClientConfig()
        config.serviceEndpoints = IntegrationHelper.mockServiceEndpoint
        config.streamingEnabled = false
        config.featuresRefreshRate = 9999
        config.segmentsRefreshRate = 9999
        config.impressionRefreshRate = 999999
        config.eventsPushRate = 999999
        config.sdkReadyTimeOut = 20000
        // Telemetry disabled: random sampling adds a second sdkReady subscription that duplicates the SDK_READY log line.
        config.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: false)

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        let factory = builder.setApiKey(apiKey)
            .setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
            .setConfig(config).build()!
        let client = factory.client
        clientsLock.lock()
        clients.append(client)
        clientsLock.unlock()
        return client
    }

    private func buildDispatcher(gated: Bool) -> HttpClientTestDispatcher {
        let firstHit = AtomicInt(0)
        let served = AtomicInt(0)
        let split = TestingHelper.buildSplit(name: "mf_split", treatment: "on")
        let change = SplitChange(splits: [split], since: -1, till: 100)
        let firstChanges = (try? Json.encodeToJson(TargetingRulesChange(
            featureFlags: change,
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)))) ?? ""
        return { [weak self] request in
            guard let self = self else { return TestDispatcherResponse(code: 500) }
            if request.isSplitEndpoint() {
                if gated && firstHit.getAndAdd(1) == 0 {
                    _ = self.gate.wait(timeout: .now() + 10)
                }
                ThreadUtils.delay(seconds: 0.3) // Simulate network
                // First request carries a small flags payload (since=-1, till=100); follow-ups are since==till
                if served.getAndAdd(1) > 0 {
                    return TestDispatcherResponse(code: 200,
                        data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(firstChanges.utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isImpressionsEndpoint() || request.isEventsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }
}

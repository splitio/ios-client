//
//  StageMarkRecorderTest.swift
//  SplitTests
//
//  FME-22007: monotonic in-memory stage marks recorded through InternalSeam.
//

import Foundation
import XCTest
@testable import Split

class StageMarkRecorderTest: XCTestCase {

    private var savedLevel: LogLevel!
    private var savedPrinter: LogPrinter!
    private var printerStub: LogPrinterStub!
    private var clients = [SplitClient]()

    override func setUp() {
        savedLevel = Logger.shared.level
        savedPrinter = Logger.shared.printer
        printerStub = LogPrinterStub()
        Logger.shared.level = .verbose
        Logger.shared.printer = printerStub
        clients = []
    }

    override func tearDown() {
        destroyClients()
        Logger.shared.level = savedLevel
        Logger.shared.printer = savedPrinter
    }

    private static let t1 = "T1 storage container built"
    private static let t2 = "T2 cache validated"
    private static let t3 = "T3 SyncManager loadData entered"
    private static let t5 = "T5 splits load started"
    private static let t6LoadStart = "T6 decode start [loadLocal]"
    private static let t6LoadEnd = "T6 decode end [loadLocal]"
    private static let t7 = "T7 processUpdated done"
    private static let t8 = "T8 splitsLoadedFromCache notified"
    private static let t10 = "T10 large segments loaded"
    private static let coldEnds = ["ColdEnd splitsUpdated notified", "ColdEnd mySegmentsUpdated notified",
                                   "ColdEnd myLargeSegmentsUpdated notified"]

    // a. Cold and warm runs record the issue-25 contract in order
    func test_coldAndWarm_recordContractMarks_inOrder_nonDecreasing() {
        let database = TestingHelper.createTestDatabase(name: UUID().uuidString)
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc6"

        let cold = StageMarkBuffer()
        XCTAssertTrue(runFactory(apiKey: apiKey, database: database, recorder: cold.sink))
        destroyClients()
        let coldNames = cold.marks.map { $0.name }
        for msg in [Self.t1, Self.t2, Self.t3, Self.t5, Self.t10] + Self.coldEnds {
            XCTAssertEqual(coldNames.filter { $0 == msg }.count, 1, "cold '\(msg)': \(coldNames)")
        }
        XCTAssertTrue(coldNames.contains { $0.hasPrefix("RunClass flagSpecHasChanged=") }, "\(coldNames)")
        XCTAssertFalse(coldNames.contains(Self.t8), "T8 must not be recorded on cold run: \(coldNames)")
        assertNonDecreasing(Self.sequenceMarks(cold.marks))

        let warm = StageMarkBuffer()
        XCTAssertTrue(runFactory(apiKey: apiKey, database: database, recorder: warm.sink))
        let marks = warm.marks
        let names = marks.map { $0.name }
        for msg in [Self.t1, Self.t2, Self.t3, Self.t5, Self.t6LoadStart, Self.t6LoadEnd, Self.t7, Self.t8,
                    Self.t10] {
            XCTAssertEqual(names.filter { $0 == msg }.count, 1, "warm '\(msg)': \(names)")
        }
        XCTAssertTrue(names.contains { $0.hasPrefix("RunClass flagSpecHasChanged=") }, "\(names)")

        let sequence = [Self.t1, Self.t2, Self.t3, Self.t5, Self.t6LoadStart, Self.t6LoadEnd, Self.t7, Self.t8]
        let positions = sequence.map { names.firstIndex(of: $0) ?? -1 }
        guard !positions.contains(-1) else { return XCTFail("Missing marks: \(positions)") }
        XCTAssertEqual(positions, positions.sorted(), "Out of order: \(sequence) at \(positions)")
        XCTAssertGreaterThan(names.firstIndex(of: Self.t10) ?? -1, names.firstIndex(of: Self.t3) ?? Int.max)
        assertNonDecreasing(Self.sequenceMarks(marks))
        let nanos = positions.map { marks[$0].nanos }
        XCTAssertEqual(nanos, nanos.sorted(), "First occurrences must be non-decreasing: \(nanos)")
        // ColdEnd marks fire from other threads, so they are not in the ordered sequence. Each must be
        // present once and not earlier than T8.
        let t8Nanos = marks[positions[positions.count - 1]].nanos
        for coldEnd in Self.coldEnds {
            let matches = marks.filter { $0.name == coldEnd }
            XCTAssertEqual(matches.count, 1, "warm '\(coldEnd)': \(names)")
            XCTAssertGreaterThanOrEqual(matches.first?.nanos ?? 0, t8Nanos,
                                        "'\(coldEnd)' earlier than T8: \(names)")
        }
    }

    // b. Default: no recorder, behaviour unchanged
    func test_default_noRecorder_unchanged() {
        XCTAssertNil(InternalSeam().markRecorder)
        TimeChecker(factoryId: 91, startTime: Date.nowMillis()).logInterval("no sink")

        printerStub.clear()
        XCTAssertTrue(runFactory(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bc7",
                                 database: TestingHelper.createTestDatabase(name: UUID().uuidString),
                                 recorder: nil))
        let lines = printerStub.logsSnapshot().filter { $0.contains("[SPTPRF]") }
        XCTAssertTrue(lines.contains { $0.contains(" \(Self.t1) at ") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.contains(" \(Self.t3) at ") }, "\(lines)")
    }

    // c. Two factories, two buffers, no cross-talk
    func test_twoFactories_separateBuffers() {
        let a = StageMarkBuffer()
        let b = StageMarkBuffer()
        XCTAssertTrue(runFactory(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bc8",
                                 database: TestingHelper.createTestDatabase(name: UUID().uuidString),
                                 recorder: a.sink))
        XCTAssertTrue(runFactory(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bc9",
                                 database: TestingHelper.createTestDatabase(name: UUID().uuidString),
                                 recorder: b.sink))
        XCTAssertEqual(a.marks.filter { $0.name == Self.t1 }.count, 1)
        XCTAssertEqual(b.marks.filter { $0.name == Self.t1 }.count, 1)
        XCTAssertEqual(a.marks.filter { $0.name == Self.t3 }.count, 1)
        XCTAssertEqual(b.marks.filter { $0.name == Self.t3 }.count, 1)
    }

    // d. Recording is independent of the log level
    func test_recordsEvenWithLogLevelNone() {
        Logger.shared.level = .none
        let buffer = StageMarkBuffer()
        XCTAssertTrue(runFactory(apiKey: "99049fd8653247c5ea42bc3c1ae2c6a42bca",
                                 database: TestingHelper.createTestDatabase(name: UUID().uuidString),
                                 recorder: buffer.sink))
        let names = buffer.marks.map { $0.name }
        XCTAssertTrue(names.contains(Self.t1), "\(names)")
        XCTAssertTrue(names.contains(Self.t3), "\(names)")
        XCTAssertTrue(printerStub.logsSnapshot().filter { $0.contains("[SPTPRF]") }.isEmpty)
    }

    // e. Concurrent appends through the sink are neither lost nor duplicated
    func test_concurrentSinkAppends_countExact_noMarkLost() {
        let threads = 8
        let perThread = 500
        let buffer = StageMarkBuffer()
        let sink = buffer.sink
        DispatchQueue.concurrentPerform(iterations: threads) { thread in
            for index in 0..<perThread {
                sink("thread \(thread) mark \(index)", UInt64(index))
            }
        }
        let names = buffer.marks.map { $0.name }
        XCTAssertEqual(names.count, threads * perThread, "Exact count of concurrent appends")
        XCTAssertEqual(Set(names).count, names.count, "Duplicate marks recorded")
        let expected = Set((0..<threads).flatMap { thread in
            (0..<perThread).map { "thread \(thread) mark \($0)" }
        })
        XCTAssertEqual(Set(names), expected, "Marks lost or unexpected")
    }

    // MARK: - Helpers

    // Marks emitted in sequence on one thread; ColdEnd marks are excluded (they fire from other threads).
    private static func sequenceMarks(_ marks: [(name: String, nanos: UInt64)]) -> [(name: String, nanos: UInt64)] {
        marks.filter { !coldEnds.contains($0.name) }
    }

    private func assertNonDecreasing(_ marks: [(name: String, nanos: UInt64)],
                                     file: StaticString = #filePath, line: UInt = #line) {
        let nanos = marks.map { $0.nanos }
        XCTAssertEqual(nanos, nanos.sorted(), "Recorded nanos decrease", file: file, line: line)
    }

    private func destroyClients() {
        for client in clients { client.destroy() }
        clients = []
    }

    private func runFactory(apiKey: String, database: SplitDatabase,
                            recorder: (@Sendable (String, UInt64) -> Void)?) -> Bool {
        let ready = XCTestExpectation(description: "ready")
        buildClient(apiKey: apiKey, database: database, recorder: recorder, ready: ready)
        return XCTWaiter().wait(for: [ready], timeout: 15) == .completed
    }

    private func buildClient(apiKey: String, database: SplitDatabase,
                             recorder: (@Sendable (String, UInt64) -> Void)?, ready: XCTestExpectation) {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildDispatcher(),
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
        config.telemetryConfigHelper = TelemetryConfigHelperStub(enabled: false)

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(database)
        if let recorder = recorder {
            _ = builder.setInternalSeam(InternalSeam(markRecorder: recorder))
        }
        let factory = builder.setApiKey(apiKey)
            .setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
            .setConfig(config).build()!
        let client = factory.client
        clients.append(client)
        client.on(event: SplitEvent.sdkReady) { ready.fulfill() }
    }

    private func buildDispatcher() -> HttpClientTestDispatcher {
        let served = AtomicInt(0)
        let split = TestingHelper.buildSplit(name: "mf_split", treatment: "on")
        let change = SplitChange(splits: [split], since: -1, till: 100)
        let firstChanges = (try? Json.encodeToJson(TargetingRulesChange(
            featureFlags: change,
            ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)))) ?? ""
        return { request in
            if request.isSplitEndpoint() {
                ThreadUtils.delay(seconds: 0.3)
                if served.getAndAdd(1) > 0 {
                    return TestDispatcherResponse(code: 200,
                        data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(firstChanges.utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            return TestDispatcherResponse(code: 200)
        }
    }
}

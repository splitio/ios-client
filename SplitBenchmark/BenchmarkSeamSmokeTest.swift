//
//  BenchmarkSeamSmokeTest.swift
//  SplitBenchmark
//
//  Proves, in the Release-Benchmark configuration, that the internal seam is reachable from the bundle
//  (testability on for the Split module), that the fixture contract holds, and that the CSV writer takes
//  marks recorded by a real factory. None of this is timing evidence.
//

import XCTest
@testable import Split

class BenchmarkSeamSmokeTest: XCTestCase {

    private var savedLevel: LogLevel!
    private var savedPrinter: LogPrinter!
    private var printerStub: LogPrinterStub!

    override func setUp() {
        savedLevel = Logger.shared.level
        savedPrinter = Logger.shared.printer
        printerStub = LogPrinterStub()
        Logger.shared.level = .verbose
        Logger.shared.printer = printerStub
    }

    override func tearDown() {
        Logger.shared.level = savedLevel
        Logger.shared.printer = savedPrinter
        printerStub.clear()
    }

    private func taskCounts() -> [Int] {
        return printerStub.logsSnapshot().compactMap { line -> Int? in
            guard let range = line.range(of: "Task count for parallel decoding: ") else { return nil }
            return Int(String(line[range.upperBound...].prefix(while: { $0.isNumber })))
        }
    }

    private func elevenFlags() -> [String] {
        return (1...11).map {
            #"{"name":"flag_\#($0)","trafficTypeName":"user","status":"ACTIVE","killed":false}"#
        }
    }

    func test_releaseSeam_widthOne_logsTaskCountOne_forElevenFlags() throws {
        let args = try BenchmarkArguments.parse(["-benchScenario", "D", "-benchWidth", "1"])
        let decoder = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting(),
                                            seam: args.makeSeam())

        let splits = decoder.decode(elevenFlags())

        XCTAssertEqual(splits.count, 11)
        XCTAssertEqual(taskCounts(), [1])
    }

    func test_releaseSeam_noWidth_logsTaskCountAboveOne_forElevenFlags() throws {
        let args = try BenchmarkArguments.parse(["-benchScenario", "D"])
        let decoder = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting(),
                                            seam: args.makeSeam())

        _ = decoder.decode(elevenFlags())

        XCTAssertGreaterThan(taskCounts().first ?? 0, 1)
    }

    func test_fixtureSeedAndHash_recordedInCsv() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("bench_fx_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let fixture = try FixtureGenerator.generate(size: .small, seed: FixtureGenerator.defaultSeed, outputDir: dir)
        let args = try BenchmarkArguments.parse(["-benchScenario", "A", "-benchFixturePath", fixture.url.path])
        let row = BenchmarkCSVRow(arguments: args, fixtureSeed: fixture.seed, fixtureHash: fixture.sha256,
                                  t0: 1, t11: 2, marks: [], thermalBefore: .nominal, thermalAfter: .nominal,
                                  wallClockStart: Date())
        let values = Dictionary(uniqueKeysWithValues: zip(BenchmarkCSVRow.columns, row.fields))

        XCTAssertEqual(values["fixtureSeed"], String(FixtureGenerator.defaultSeed))
        XCTAssertEqual(values["fixtureHash"], FixtureGenerator.sha256Hex(of: try Data(contentsOf: fixture.url)))
        XCTAssertEqual(values["fixtureHash"]?.count, 64)
    }

    // One real factory, no scenario, no loop. Offline endpoints: T1..T3 are recorded before any network use.
    func test_simulatorSmoke_writesRowWithNonZeroMarks() throws {
        let buffer = StageMarkBuffer()
        let args = try BenchmarkArguments.parse(["-benchScenario", "A", "-benchLogging", "off"])
        let config = SplitClientConfig()
        config.serviceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: "http://127.0.0.1:1")
            .set(eventsEndpoint: "http://127.0.0.1:1").build()
        config.streamingEnabled = false
        config.sdkReadyTimeOut = 20000
        config.logLevel = args.logging.configLogLevel

        let t0 = DispatchTime.now().uptimeNanoseconds
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setInternalSeam(args.makeSeam(markRecorder: buffer.sink))
        let factory = try XCTUnwrap(builder.setApiKey("bench_smoke_api_key_\(UUID().uuidString)")
            .setKey(Key(matchingKey: "bench_user")).setConfig(config).build())
        let client = factory.client
        defer { client.destroy() }

        let deadline = Date().addingTimeInterval(15)
        while !buffer.marks.contains(where: { $0.name == "T3 SyncManager loadData entered" }) && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        let t11 = DispatchTime.now().uptimeNanoseconds

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bench_\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: url) }
        let row = BenchmarkCSVRow(arguments: args, fixtureSeed: 1, fixtureHash: "h", t0: t0, t11: t11,
                                  marks: buffer.marks, thermalBefore: ProcessInfo.processInfo.thermalState,
                                  thermalAfter: ProcessInfo.processInfo.thermalState, wallClockStart: Date())
        try row.append(to: url)

        let lines = try String(contentsOf: url).components(separatedBy: "\n")
        let written = Dictionary(uniqueKeysWithValues: zip(lines[0].components(separatedBy: ","),
                                                           lines[1].components(separatedBy: ",")))
        for column in ["T1", "T2", "T3"] {
            XCTAssertGreaterThan(UInt64(written[column] ?? "") ?? 0, 0, "\(column) in \(lines[1])")
        }
    }
}

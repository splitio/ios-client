//
//  BenchmarkRunTest.swift
//  SplitBenchmark
//
//  Thin XCTest wrapper over `BenchmarkRunner.run`, the one shared entry (also meant for a host app, issue 42).
//  Launch arguments come from the process; a test host may also pass them as the BENCH_ARGS environment
//  variable (xcodebuild: TEST_RUNNER_BENCH_ARGS), because xcodebuild does not forward launch arguments to the
//  test process. No scenario logic lives in this file.
//

import XCTest
@testable import Split

class BenchmarkRunTest: XCTestCase {

    typealias SharedRun = (BenchmarkArguments, URL) throws -> [BenchmarkCSVRow]

    /// The wrapper path: parse the arguments, call the shared function with the resolved CSV URL.
    static func runFromLaunch(_ argv: [String],
                              run: SharedRun = { try BenchmarkRunner.run(arguments: $0, csvURL: $1) }) throws
        -> [BenchmarkCSVRow] {
        let arguments = try BenchmarkArguments.parse(argv)
        return try run(arguments, BenchmarkRunner.csvURL(for: arguments))
    }

    static func processArguments() -> [String] {
        let fromEnvironment = ProcessInfo.processInfo.environment["BENCH_ARGS"]?
            .split(separator: " ").map(String.init) ?? []
        return CommandLine.arguments + fromEnvironment
    }

    func test_wrapperCallsTheSharedRunFunction_withParsedArgumentsAndCsvURL() throws {
        var received = [(BenchmarkArguments, URL)]()
        let sentinel = [BenchmarkCSVRow(arguments: try BenchmarkArguments.parse(["-benchScenario", "A"]),
                                        fixtureSeed: 1, fixtureHash: "h", t0: 1, t11: 2, marks: [],
                                        thermalBefore: .nominal, thermalAfter: .nominal, wallClockStart: Date())]

        let rows = try Self.runFromLaunch(["-benchScenario", "C2", "-benchCSVPath", "/tmp/shared.csv"]) {
            received.append(($0, $1))
            return sentinel
        }

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.0.scenario, .c2)
        XCTAssertEqual(received.first?.1.path, "/tmp/shared.csv")
        XCTAssertEqual(rows, sentinel)
    }

    func test_wrapper_surfacesArgumentErrors_withoutCallingTheSharedFunction() {
        var called = false

        XCTAssertThrowsError(try Self.runFromLaunch(["-benchScenario", "nope"]) { _, _ in
            called = true
            return []
        })
        XCTAssertFalse(called)
    }

    func test_csvURL_defaultsToDocumentsBenchmarkCsv() throws {
        let url = BenchmarkRunner.csvURL(for: try BenchmarkArguments.parse(["-benchScenario", "A"]))

        XCTAssertEqual(url.lastPathComponent, "benchmark.csv")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Documents")
    }

    func test_sharedFunction_writesHeaderAndRowsToTheCsv_throughAnInjectedDriver() throws {
        let csv = FileManager.default.temporaryDirectory.appendingPathComponent("shared_\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: csv) }
        let driver = FakeBenchmarkDriver()

        let rows = try BenchmarkRunner.run(arguments: try BenchmarkTestFixtures.arguments("C"), csvURL: csv,
                                           driver: driver, payload: BenchmarkTestFixtures.payload())

        let lines = try String(contentsOf: csv).split(separator: "\n").map(String.init)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], BenchmarkCSVRow.columns.joined(separator: ","))
    }

    /// The real run. Without a `-benchScenario` launch argument (a plain test run) it is skipped.
    func test_runScenarioFromLaunchArguments() throws {
        let argv = Self.processArguments()
        try XCTSkipUnless(argv.contains("-benchScenario"), "no -benchScenario launch argument")

        let rows = try Self.runFromLaunch(argv)

        XCTAssertFalse(rows.isEmpty)
    }
}

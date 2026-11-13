//
//  BenchmarkRealScenariosTest.swift
//  SplitBenchmark
//
//  Simulator run of every scenario through the shared runner and the real driver. Deterministic correctness
//  only (a row with non-zero marks); never timing evidence.
//

import XCTest
@testable import Split

class BenchmarkRealScenariosTest: XCTestCase {

    private var server: LoopbackStubServer?
    private var endpoint: String?

    override func setUpWithError() throws {
        server = try LoopbackStubServer()
        endpoint = server?.start()
    }

    override func tearDown() { server?.stop() }

    private func run(_ name: String) throws -> [[String: String]] {
        let csv = FileManager.default.temporaryDirectory.appendingPathComponent("real_\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: csv) }
        let args = try BenchmarkArguments.parse(["-benchScenario", name, "-benchFixtureSize", "small",
                                                 "-benchLogging", "off", "-benchSHA", "sim"]
                                                + (name == "D" ? ["-benchEndpoint", try XCTUnwrap(endpoint)] : []))

        // Unique keys: another test in this process may hold the shared benchmark keys' stores open, and D
        // deletes the store. (A real run is one scenario per process.)
        let unique = UUID().uuidString.prefix(4)
        let scratch = FileManager.default.temporaryDirectory.appendingPathComponent("real_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let payload = try BenchmarkPayload.make(arguments: args, scratchDirectory: scratch)
        let driver = RealBenchmarkDriver(arguments: args, payload: payload)
        let runner = BenchmarkScenarioRunner(arguments: args, driver: driver, payload: payload,
                                             apiKeys: ("\(unique)-bench-alpha-aaaa", "\(unique)-bench-beta-bbbb"))
        for row in try runner.run() { try row.append(to: csv) }

        let lines = try String(contentsOf: csv).split(separator: "\n").map(String.init)
        let header = lines[0].components(separatedBy: ",")
        return lines.dropFirst().map { Dictionary(uniqueKeysWithValues: zip(header, $0.components(separatedBy: ","))) }
    }

    private func nonZero(_ row: [String: String], _ column: String, _ scenario: String,
                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThan(UInt64(row[column] ?? "") ?? 0, 0, "\(scenario) \(column): \(row)", file: file, line: line)
    }

    func test_everyScenario_writesRowsWithNonZeroMarks() throws {
        let expectedRows = ["A": 1, "B": 2, "C": 2, "C-bg": 2, "C2": 2, "D": 1, "E": 2, "stress2x": 1, "stress4x": 1]
        for (name, count) in expectedRows.sorted(by: { $0.key < $1.key }) {
            let rows: [[String: String]]
            do {
                rows = try run(name)
            } catch {
                XCTFail("\(name) threw \(String(reflecting: error))")
                continue
            }

            XCTAssertEqual(rows.count, count, name)
            for row in rows {
                XCTAssertEqual(row["scenario"], name)
                for column in ["T0", "T1", "T2", "T3", "T11"] { nonZero(row, column, name) }
                if name != "D" {
                    nonZero(row, "T8", name)
                    XCTAssertEqual(row["cacheHit"], "true", name)
                }
                XCTAssertGreaterThan(UInt64(row["T11"] ?? "") ?? 0, UInt64(row["T0"] ?? "") ?? 0, name)
            }
            XCTAssertEqual(rows.map { $0["factoryIndex"] }, count == 2 ? ["1", "2"] : ["1"], name)
        }
    }
}

//
//  BenchmarkRunner.swift
//  SplitBenchmark
//
//  FME-22007: the ONE shared entry that runs a scenario for real. The XCTest wrapper and, later, a host app
//  call `BenchmarkRunner.run`; no scenario logic lives in an XCTestCase. This file does not import XCTest.
//

import Foundation

enum BenchmarkRunner {

    /// Runs the scenario in `arguments` once with the real driver and appends one CSV row per factory to
    /// `csvURL`. Returns the rows.
    @discardableResult
    static func run(arguments: BenchmarkArguments, csvURL: URL) throws -> [BenchmarkCSVRow] {
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("benchmark_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        let payload = try BenchmarkPayload.make(arguments: arguments, scratchDirectory: scratch)
        let driver = RealBenchmarkDriver(arguments: arguments, payload: payload)
        return try run(arguments: arguments, csvURL: csvURL, driver: driver, payload: payload)
    }

    /// Same as `run(arguments:csvURL:)` with the driver supplied by the caller.
    @discardableResult
    static func run(arguments: BenchmarkArguments, csvURL: URL, driver: BenchmarkDriver,
                    payload: BenchmarkPayload) throws -> [BenchmarkCSVRow] {
        let rows = try BenchmarkScenarioRunner(arguments: arguments, driver: driver, payload: payload).run()
        for row in rows { try row.append(to: csvURL) }
        return rows
    }

    /// `-benchCSVPath`, or Documents/benchmark.csv.
    static func csvURL(for arguments: BenchmarkArguments) -> URL {
        if let path = arguments.csvPath, !path.isEmpty { return URL(fileURLWithPath: path) }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("benchmark.csv")
    }
}

extension BenchmarkPayload {

    /// Stress scenarios generate the chosen fixture size with its flag count multiplied (issue-26 custom
    /// parameters, same seed). Every other scenario reads `-benchFixturePath`; with no path it generates the
    /// chosen size unchanged.
    static func make(arguments: BenchmarkArguments, scratchDirectory: URL) throws -> BenchmarkPayload {
        let multiplier = arguments.scenario.payloadMultiplier
        let seed = FixtureGenerator.defaultSeed
        if multiplier == 1 && !arguments.fixturePath.isEmpty {
            let url = URL(fileURLWithPath: arguments.fixturePath)
            let hash = FixtureGenerator.sha256Hex(of: try Data(contentsOf: url))
            return BenchmarkPayload(fileURL: url, seed: seed, hash: hash, multiplier: 1)
        }
        let base = arguments.fixtureSize.params(seed: seed)
        let params = FixtureParams(flags: base.flags * multiplier, sets: base.sets,
                                   flagsWithSets: base.flagsWithSets, maxSetsPerFlag: base.maxSetsPerFlag,
                                   meanBytes: base.meanBytes, medianBytes: base.medianBytes,
                                   maxBytes: base.maxBytes, meanConditions: base.meanConditions,
                                   maxConditions: base.maxConditions, seed: seed)
        let result = try FixtureGenerator.generate(params, outputDir: scratchDirectory,
                                                   fileName: "fixture_\(arguments.fixtureSize.rawValue)_x\(multiplier).json")
        return BenchmarkPayload(fileURL: result.url, seed: result.seed, hash: result.sha256, multiplier: multiplier)
    }
}

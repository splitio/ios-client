//
//  BenchmarkPayloadTest.swift
//  SplitBenchmark
//

import XCTest
@testable import Split

class BenchmarkPayloadTest: XCTestCase {

    private var scratch: URL!

    override func setUpWithError() throws {
        scratch = FileManager.default.temporaryDirectory.appendingPathComponent("bench_payload_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratch)
    }

    private func flagCount(_ payload: BenchmarkPayload) throws -> Int {
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: payload.fileURL)) as? [String: Any]
        return (object?["splits"] as? [Any])?.count ?? -1
    }

    private func payload(_ scenario: String) throws -> BenchmarkPayload {
        let args = try BenchmarkArguments.parse(["-benchScenario", scenario, "-benchFixtureSize", "small"])
        return try BenchmarkPayload.make(arguments: args, scratchDirectory: scratch)
    }

    func test_stressMultipliers_scaleTheFlagCount_ofTheChosenSize() throws {
        let base = FixtureSize.small.params(seed: FixtureGenerator.defaultSeed).flags

        XCTAssertEqual(try flagCount(try payload("A")), base)
        XCTAssertEqual(try flagCount(try payload("stress2x")), base * 2)
        XCTAssertEqual(try flagCount(try payload("stress4x")), base * 4)
        XCTAssertEqual(try payload("stress2x").multiplier, 2)
        XCTAssertEqual(try payload("stress4x").multiplier, 4)
        XCTAssertEqual(try payload("A").multiplier, 1)
    }

    func test_hashAndSeed_describeTheGeneratedFile() throws {
        let made = try payload("stress2x")

        XCTAssertEqual(made.hash, FixtureGenerator.sha256Hex(of: try Data(contentsOf: made.fileURL)))
        XCTAssertEqual(made.seed, FixtureGenerator.defaultSeed)
        XCTAssertNotEqual(made.hash, try payload("stress4x").hash)
    }

    func test_fixturePath_isReadAsIs_forNonStressScenarios() throws {
        let fixture = try FixtureGenerator.generate(size: .small, seed: 5, outputDir: scratch)
        let args = try BenchmarkArguments.parse(["-benchScenario", "B", "-benchFixturePath", fixture.url.path])

        let made = try BenchmarkPayload.make(arguments: args, scratchDirectory: scratch)

        XCTAssertEqual(made.fileURL, fixture.url)
        XCTAssertEqual(made.hash, fixture.sha256)
        XCTAssertEqual(made.multiplier, 1)
    }

    func test_stressIgnoresFixturePath_andUsesTheMultipliedSize() throws {
        let fixture = try FixtureGenerator.generate(size: .small, seed: 5, outputDir: scratch)
        let args = try BenchmarkArguments.parse(["-benchScenario", "stress2x", "-benchFixtureSize", "small",
                                                 "-benchFixturePath", fixture.url.path])

        let made = try BenchmarkPayload.make(arguments: args, scratchDirectory: scratch)

        XCTAssertNotEqual(made.fileURL, fixture.url)
        XCTAssertEqual(try flagCount(made), fixture.flagCount * 2)
    }
}

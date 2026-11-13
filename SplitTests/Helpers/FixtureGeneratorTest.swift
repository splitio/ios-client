//
//  FixtureGeneratorTest.swift
//  SplitTests
//

import XCTest
@testable import Split

// Tests for the deterministic fixture generator (FME-22007, section 6.4).
// Every expected number below is a literal taken from the spec's aggregates,
// not read back from the generator.
class FixtureGeneratorTest: XCTestCase {

    private var workDir: URL!

    override func setUpWithError() throws {
        workDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FixtureGeneratorTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workDir)
    }

    private func outputDir(_ name: String) -> URL {
        workDir.appendingPathComponent(name, isDirectory: true)
    }

    private func splitsArray(_ url: URL) throws -> [[String: Any]] {
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(root["splits"] as? [[String: Any]])
    }

    private func setNames(_ flag: [String: Any]) -> [String] {
        flag["sets"] as? [String] ?? []
    }

    func test_sha256_matchesKnownVector() {
        // NIST FIPS 180-2 vector for "abc".
        XCTAssertEqual(FixtureGenerator.sha256Hex(of: Data("abc".utf8)),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func test_sameSeed_sameHash() throws {
        let a = try FixtureGenerator.generate(size: .small, seed: FixtureGenerator.defaultSeed,
                                              outputDir: outputDir("a"))
        // The clock is in whole seconds, so wait past a second boundary: output that
        // depends on wall-clock time would then differ between the two runs.
        Thread.sleep(forTimeInterval: 1.1)
        let b = try FixtureGenerator.generate(size: .small, seed: FixtureGenerator.defaultSeed,
                                              outputDir: outputDir("b"))
        XCTAssertEqual(a.sha256, b.sha256)
        XCTAssertEqual(a.sha256.count, 64)
        XCTAssertEqual(try Data(contentsOf: a.url), try Data(contentsOf: b.url))
    }

    func test_differentSeed_differentHash() throws {
        let a = try FixtureGenerator.generate(size: .small, seed: 22007, outputDir: outputDir("a"))
        let b = try FixtureGenerator.generate(size: .small, seed: 22008, outputDir: outputDir("b"))
        XCTAssertNotEqual(a.sha256, b.sha256)
    }

    func test_threeSizesGenerated() throws {
        XCTAssertEqual(FixtureSize.allCases, [.small, .medium, .large])

        XCTAssertEqual(FixtureSize.small.params(seed: 22007),
                       FixtureParams(flags: 177, sets: 2, flagsWithSets: 19, maxSetsPerFlag: 2,
                                     meanBytes: 1263, medianBytes: 1395, maxBytes: 2970,
                                     meanConditions: 1.5, maxConditions: 3, seed: 22007))
        XCTAssertEqual(FixtureSize.medium.params(seed: 22007),
                       FixtureParams(flags: 1200, sets: 8, flagsWithSets: 600, maxSetsPerFlag: 3,
                                     meanBytes: 1400, medianBytes: 1390, maxBytes: 8000,
                                     meanConditions: 1.7, maxConditions: 8, seed: 22007))
        XCTAssertEqual(FixtureSize.large.params(seed: 22007),
                       FixtureParams(flags: 4585, sets: 21, flagsWithSets: 3730, maxSetsPerFlag: 4,
                                     meanBytes: 1517, medianBytes: 1382, maxBytes: 23124,
                                     meanConditions: 1.9, maxConditions: 19, seed: 22007))

        XCTAssertEqual(FixtureGenerator.defaultSeed, 22007)

        for size in FixtureSize.allCases {
            let result = try FixtureGenerator.generate(size: size, seed: FixtureGenerator.defaultSeed,
                                                       outputDir: outputDir(size.rawValue))
            XCTAssertEqual(result.url.lastPathComponent, "fixture_\(size.rawValue)_22007.json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.url.path))
            XCTAssertEqual(result.seed, 22007)
        }
    }

    func test_countsMatchFlagsAndSets() throws {
        for size in FixtureSize.allCases {
            let p = size.params(seed: FixtureGenerator.defaultSeed)
            let r = try FixtureGenerator.generate(size: size, seed: FixtureGenerator.defaultSeed,
                                                  outputDir: outputDir(size.rawValue))
            let splits = try splitsArray(r.url)

            XCTAssertEqual(splits.count, p.flags, "\(size) flag count")
            XCTAssertEqual(r.flagCount, p.flags, "\(size) reported flag count")

            let withSets = splits.filter { $0["sets"] != nil }
            XCTAssertEqual(withSets.count, p.flagsWithSets, "\(size) flags with sets")
            XCTAssertTrue(withSets.allSatisfy { !setNames($0).isEmpty }, "\(size) flagged flag has no sets")

            let allSets = Set(splits.flatMap { setNames($0) })
            XCTAssertEqual(allSets.count, p.sets, "\(size) distinct sets")
            XCTAssertEqual(r.setCount, p.sets, "\(size) reported set count")

            let perFlag = splits.map { setNames($0).count }
            XCTAssertLessThanOrEqual(perFlag.max() ?? 0, p.maxSetsPerFlag, "\(size) sets per flag")
            XCTAssertEqual(perFlag.max() ?? 0, p.maxSetsPerFlag, "\(size) max sets per flag reached")

            XCTAssertTrue(splits.allSatisfy { ($0["status"] as? String) == "ACTIVE" }, "\(size) status")
            XCTAssertTrue(splits.allSatisfy { ($0["killed"] as? Bool) == false }, "\(size) killed")
        }
    }

    func test_averageSizeWithinTolerance() throws {
        for size in FixtureSize.allCases {
            let p = size.params(seed: FixtureGenerator.defaultSeed)
            let r = try FixtureGenerator.generate(size: size, seed: FixtureGenerator.defaultSeed,
                                                  outputDir: outputDir(size.rawValue))

            // Tolerance D7: mean within 5 percent of the customer aggregate.
            let meanError = abs(r.meanFlagBytes - Double(p.meanBytes)) / Double(p.meanBytes)
            XCTAssertLessThanOrEqual(meanError, 0.05, "\(size) mean \(r.meanFlagBytes) vs \(p.meanBytes)")

            XCTAssertLessThanOrEqual(r.maxFlagBytes, p.maxBytes, "\(size) max over cap")
            if size == .large {
                XCTAssertGreaterThanOrEqual(Double(r.maxFlagBytes), 0.8 * Double(p.maxBytes),
                                            "large max \(r.maxFlagBytes) vs \(p.maxBytes)")
                let medianError = abs(Double(r.medianFlagBytes) - Double(p.medianBytes)) / Double(p.medianBytes)
                XCTAssertLessThanOrEqual(medianError, 0.15,
                                         "large median \(r.medianFlagBytes) vs \(p.medianBytes)")
            }
        }
    }

    func test_decoderAcceptsOutput() throws {
        for size in FixtureSize.allCases {
            let p = size.params(seed: FixtureGenerator.defaultSeed)
            let r = try FixtureGenerator.generate(size: size, seed: FixtureGenerator.defaultSeed,
                                                  outputDir: outputDir(size.rawValue))

            // Each flag object is handed to the decoder as its own JSON string.
            let flagStrings: [String] = try splitsArray(r.url).map { flag in
                let data = try JSONSerialization.data(withJSONObject: flag)
                return try XCTUnwrap(String(data: data, encoding: .utf8))
            }

            let decoder = SplitsParallelDecoder(minTaskPerThread: 15, timeChecker: TimeChecker.forTesting())
            let decoded = decoder.decode(flagStrings)

            XCTAssertEqual(decoded.count, p.flags, "\(size) decoded flag count")
            XCTAssertEqual(Set(decoded.map { $0.name }).count, p.flags, "\(size) decoded names unique")
            XCTAssertEqual(decoded.filter { $0.sets != nil }.count, p.flagsWithSets, "\(size) decoded flags with sets")
            let unionOfSets = decoded.reduce(into: Set<String>()) { $0.formUnion($1.sets ?? []) }
            XCTAssertEqual(unionOfSets.count, p.sets, "\(size) decoded distinct sets")
        }
    }
}

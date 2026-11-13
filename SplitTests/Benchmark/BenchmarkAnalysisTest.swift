//
//  BenchmarkAnalysisTest.swift
//  SplitTests
//
//  FME-22007 issue 29: tests for the pure benchmark analysis. All data is synthetic and generated here.
//  No timing is measured; every expected number is computed by hand from the fixtures.
//

import Foundation
import XCTest

class BenchmarkAnalysisTest: XCTestCase {

    // A copy of SplitBenchmark/BenchmarkCSVRow.columns (this target cannot import the benchmark target).
    private let contractColumns = [
        "scenario", "sha", "runIndex", "buildVariant", "width", "fixtureSeed", "fixtureHash",
        "T0", "T1", "T2", "T3", "T5",
        "T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end",
        "T6_forceParsing_start", "T6_forceParsing_end",
        "T6_loadLocal_start", "T6_loadLocal_end", "T6Count",
        "T7", "T8", "T10",
        "coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated", "coldEnd_myLargeSegmentsUpdated",
        "T11", "flagSpecHasChanged", "filterHasChanged", "forceParsingRan", "cacheHit", "decodeCount",
        "thermalStateBefore", "thermalStateAfter", "idleGapSeconds", "installState", "wallClockStart", "readyAPI"
    ]

    private let baseNanos: UInt64 = 1_000_000_000
    private let baseWall = "2026-11-13T10:00:00.000Z"

    // MARK: Fixture helpers

    private func ns(_ ms: Double) -> UInt64 { UInt64((ms * 1_000_000).rounded()) }

    private func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func csv(_ rows: [[String: String]], header: [String]? = nil) -> String {
        let columns = header ?? contractColumns
        var text = columns.joined(separator: ",") + "\n"
        for row in rows {
            text += columns.map { escape(row[$0] ?? "") }.joined(separator: ",") + "\n"
        }
        return text
    }

    private func runs(_ rows: [[String: String]]) throws -> [BenchmarkAnalysis.Run] {
        return try BenchmarkAnalysis.parseRuns(csv(rows))
    }

    private func wall(secondsAfterBase seconds: Int) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        let base = formatter.date(from: baseWall)!
        return formatter.string(from: base.addingTimeInterval(TimeInterval(seconds)))
    }

    /// A warm cache-hit row. stagesMs are the deltas T0>T1, T1>T2, T2>T3, T3>T5, T5>T7, T7>T8, T8>T11.
    /// T10 equals T8 (ties pick the splits branch). The loadLocal decode spans T5..T7.
    private func warm(_ index: Int, stagesMs: [Double] = [10, 10, 10, 10, 10, 10, 10],
                      scenario: String = "A", build: String = "logging-off", sha: String = "s1",
                      wallClock: String? = nil, _ extra: [String: String] = [:]) -> [String: String] {
        precondition(stagesMs.count == 7)
        var fields: [String: String] = [
            "scenario": scenario, "sha": sha, "runIndex": String(index), "buildVariant": build,
            "cacheHit": "true", "flagSpecHasChanged": "false", "filterHasChanged": "false",
            "forceParsingRan": "false", "decodeCount": "1",
            "thermalStateBefore": "nominal", "thermalStateAfter": "nominal",
            "installState": "relaunch", "wallClockStart": wallClock ?? baseWall
        ]
        var t = baseNanos
        fields["T0"] = String(t)
        let names = ["T1", "T2", "T3", "T5", "T7", "T8"]
        for (i, name) in names.enumerated() {
            t += ns(stagesMs[i])
            fields[name] = String(t)
        }
        fields["T10"] = fields["T8"]
        fields["T6_loadLocal_start"] = fields["T5"]
        fields["T6_loadLocal_end"] = fields["T7"]
        t += ns(stagesMs[6])
        fields["T11"] = String(t)
        return fields.merging(extra) { _, new in new }
    }

    /// A cold-miss row. stagesMs are the deltas T0>T1, T1>T2, T2>T3, T3>T5, T5>c1, c1>c2, c2>c3, c3>T11 where
    /// c1..c3 are the coldEnd marks in time order given by coldOrder. No T7, T8 or T10.
    private func cold(_ index: Int, stagesMs: [Double] = [10, 10, 10, 10, 10, 10, 10, 10],
                      coldOrder: [String] = ["coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated",
                                             "coldEnd_myLargeSegmentsUpdated"],
                      scenario: String = "C", cacheHit: String = "false",
                      _ extra: [String: String] = [:]) -> [String: String] {
        precondition(stagesMs.count == 8)
        var fields: [String: String] = [
            "scenario": scenario, "sha": "s1", "runIndex": String(index), "buildVariant": "logging-off",
            "cacheHit": cacheHit, "flagSpecHasChanged": "false", "filterHasChanged": "false",
            "forceParsingRan": "false", "decodeCount": "1",
            "thermalStateBefore": "nominal", "thermalStateAfter": "nominal",
            "installState": "relaunch", "wallClockStart": baseWall
        ]
        var t = baseNanos
        fields["T0"] = String(t)
        let names = ["T1", "T2", "T3", "T5"] + coldOrder
        for (i, name) in names.enumerated() {
            t += ns(stagesMs[i])
            fields[name] = String(t)
        }
        t += ns(stagesMs[7])
        fields["T11"] = String(t)
        return fields.merging(extra) { _, new in new }
    }

    // MARK: 1. Parser

    func test_parse_headerMatchesContract() throws {
        XCTAssertEqual(BenchmarkAnalysis.columns, contractColumns)
        XCTAssertEqual(contractColumns.count, 37)

        XCTAssertEqual(try BenchmarkAnalysis.parse(csv([])).count, 0)

        var swapped = contractColumns
        swapped.swapAt(0, 1)
        XCTAssertThrowsError(try BenchmarkAnalysis.parse(csv([], header: swapped))) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .headerMismatch)
        }
        XCTAssertThrowsError(try BenchmarkAnalysis.parse(csv([], header: contractColumns + ["extra"]))) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .headerMismatch)
        }
        XCTAssertThrowsError(try BenchmarkAnalysis.parse(csv([], header: Array(contractColumns.dropLast())))) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .headerMismatch)
        }
        XCTAssertThrowsError(try BenchmarkAnalysis.parse("")) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .headerMismatch)
        }
    }

    func test_parse_emptyFieldIsMissing() throws {
        var row = warm(0)
        row["T7"] = ""
        let rows = try BenchmarkAnalysis.parse(csv([row]))
        XCTAssertEqual(rows.count, 1)
        XCTAssertNil(rows[0]["T7"])
        XCTAssertEqual(rows[0]["T0"], "1000000000")
        XCTAssertEqual(rows[0]["scenario"], "A")
        XCTAssertNil(rows[0]["width"])
        XCTAssertNil(rows[0]["noSuchColumn"])

        let parsed = try BenchmarkAnalysis.parseRuns(csv([row]))
        XCTAssertNil(parsed[0].marks["T7"])
        XCTAssertEqual(parsed[0].marks["T5"], baseNanos + ns(40))
    }

    func test_parse_quotedFieldsAndLineEndings() throws {
        var row = warm(0)
        row["sha"] = "a,\"b\"\nc"
        row["fixtureHash"] = "x"
        var text = csv([row, warm(1)])
        let rows = try BenchmarkAnalysis.parse(text)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0]["sha"], "a,\"b\"\nc")
        XCTAssertEqual(rows[1]["sha"], "s1")

        text = text.replacingOccurrences(of: "\n", with: "\r\n")
        let crlf = try BenchmarkAnalysis.parse(text.replacingOccurrences(of: "a,\"b\"\r\nc", with: "a,\"b\"\nc"))
        XCTAssertEqual(crlf.count, 2)
        XCTAssertEqual(crlf[1]["T0"], "1000000000")
    }

    func test_parse_malformedRowsThrow() throws {
        let good = csv([warm(0)])
        XCTAssertThrowsError(try BenchmarkAnalysis.parse(good + "A,s1,1\n")) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .malformedRow(line: 3))
        }
        var bad = warm(0)
        bad["runIndex"] = "notanumber"
        XCTAssertThrowsError(try BenchmarkAnalysis.parseRuns(csv([bad]))) { error in
            XCTAssertEqual(error as? BenchmarkAnalysis.Failure, .malformedRow(line: 2))
        }
    }

    // MARK: 2. Stats

    func test_median_p90_fixture() {
        XCTAssertEqual(BenchmarkAnalysis.median([3, 1, 2]), 2)
        XCTAssertEqual(BenchmarkAnalysis.median([4, 1, 3, 2]), 2.5)
        XCTAssertEqual(BenchmarkAnalysis.median([7]), 7)
        XCTAssertNil(BenchmarkAnalysis.median([]))

        let ten = (1...10).map { Double($0) }
        XCTAssertEqual(BenchmarkAnalysis.p90(ten.reversed()), 9)           // ceil(9.0)-1 = index 8
        let eleven = (1...11).map { Double($0) }
        XCTAssertEqual(BenchmarkAnalysis.p90(eleven), 10)                  // ceil(9.9)-1 = index 9
        let twenty = (1...20).map { Double($0) }
        XCTAssertEqual(BenchmarkAnalysis.p90(twenty), 18)                  // ceil(18.0)-1 = index 17
        XCTAssertEqual(BenchmarkAnalysis.p90([5]), 5)
        XCTAssertEqual(BenchmarkAnalysis.p90([9, 1]), 9)                   // ceil(1.8)-1 = index 1
        XCTAssertNil(BenchmarkAnalysis.p90([]))

        XCTAssertEqual(BenchmarkAnalysis.minimum([4, -2, 9]), -2)
        XCTAssertEqual(BenchmarkAnalysis.maximum([4, -2, 9]), 9)
        XCTAssertNil(BenchmarkAnalysis.minimum([]))
        XCTAssertNil(BenchmarkAnalysis.maximum([]))

        let stats = BenchmarkAnalysis.stats([4, 1, 3, 2])
        XCTAssertEqual(stats?.count, 4)
        XCTAssertEqual(stats?.median, 2.5)
        XCTAssertEqual(stats?.p90, 4)
        XCTAssertEqual(stats?.min, 1)
        XCTAssertEqual(stats?.max, 4)
        XCTAssertNil(BenchmarkAnalysis.stats([]))
    }

    // MARK: 3. Bootstrap

    func test_splitMix64_knownFirstOutput() {
        var generator = BenchmarkAnalysis.SplitMix64(seed: 0)
        XCTAssertEqual(generator.next(), 0xE220A8397B1DCDAF)
        var again = BenchmarkAnalysis.SplitMix64(seed: 0)
        XCTAssertEqual(again.next(), 0xE220A8397B1DCDAF)
    }

    func test_bootstrap_percentileIndices() {
        let tenThousand = (0..<10_000).map { Double($0) }
        let wide = BenchmarkAnalysis.percentileInterval(sortedResamples: tenThousand)
        XCTAssertEqual(wide?.lower, 250)     // floor(0.025 * 10000)
        XCTAssertEqual(wide?.upper, 9749)    // ceil(0.975 * 10000) - 1
        let forty = (0..<40).map { Double($0) }
        let narrow = BenchmarkAnalysis.percentileInterval(sortedResamples: forty)
        XCTAssertEqual(narrow?.lower, 1)     // floor(1.0)
        XCTAssertEqual(narrow?.upper, 38)    // ceil(39.0) - 1
        let hundred = (0..<100).map { Double($0) }
        let mid = BenchmarkAnalysis.percentileInterval(sortedResamples: hundred)
        XCTAssertEqual(mid?.lower, 2)        // floor(2.5)
        XCTAssertEqual(mid?.upper, 97)       // ceil(97.5) - 1
        XCTAssertNil(BenchmarkAnalysis.percentileInterval(sortedResamples: []))
    }

    func test_bootstrap_ci_fixedSeed() throws {
        // 40 distinct deltas ((37 i mod 101) / 4), each pair its own block.
        let baseline: [Double] = (0..<40).map { 100 + Double(($0 * 7) % 11) }
        let deltas: [Double] = (0..<40).map { Double(($0 * 37) % 101) / 4 }
        let candidate = zip(baseline, deltas).map { $0 + $1 }
        let blocks = Array(0..<40)

        let first = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                               blocks: blocks, seed: 42)
        let second = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                                blocks: blocks, seed: 42)
        XCTAssertNotNil(first)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first?.point, 12.125)   // median of the 40 deltas: mean of the 20th and 21st smallest
        XCTAssertEqual(first?.point, BenchmarkAnalysis.median(deltas))
        XCTAssertLessThan(first!.lower, first!.point)
        XCTAssertGreaterThan(first!.upper, first!.point)
        XCTAssertGreaterThanOrEqual(first!.lower, 0)
        XCTAssertLessThanOrEqual(first!.upper, 25)
        XCTAssertEqual(first!.halfWidth, (first!.upper - first!.lower) / 2)

        // With few resamples the percentiles are noisy enough that the seed shows.
        let low42 = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                               blocks: blocks, resamples: 100, seed: 42)
        let low43 = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                               blocks: blocks, resamples: 100, seed: 43)
        XCTAssertNotEqual(low42, low43)
        XCTAssertNotEqual(low42, first)   // and the resample count matters
    }

    func test_bootstrap_constantDelta() throws {
        let baseline: [Double] = [10, 20, 35, 41, 52, 60, 77, 80]
        let candidate = baseline.map { $0 + 5 }
        let result = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                                blocks: [0, 1, 2, 3, 4, 5, 6, 7], resamples: 500,
                                                                seed: 7)
        XCTAssertEqual(result, BenchmarkAnalysis.Interval(point: 5, lower: 5, upper: 5))
        XCTAssertEqual(result?.halfWidth, 0)
    }

    func test_bootstrap_pairingIsPreserved() throws {
        // Huge between-block variation, constant within-pair delta: a paired bootstrap is exact.
        let baseline = (0..<10).map { 1000.0 * Double($0) }
        let candidate = baseline.map { $0 + 3 }
        let blocks = Array(0..<10)
        let result = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                                blocks: blocks, resamples: 2000, seed: 99)
        XCTAssertEqual(result?.lower, 3)
        XCTAssertEqual(result?.upper, 3)
        // An unpaired bootstrap would resample the medians of each side independently: baseline medians
        // alone move by thousands, so this tight interval can only come from paired deltas.
    }

    func test_bootstrap_blocksAreKeptTogether() throws {
        // Every block holds one pair with delta 0 and one with delta 10. Resampling whole blocks always yields
        // ten zeros and ten tens per resample, so every resample median is exactly 5.
        var baseline = [Double]()
        var candidate = [Double]()
        var blocks = [Int]()
        for block in 0..<10 {
            baseline += [Double(block) * 100, Double(block) * 100 + 1]
            candidate += [Double(block) * 100, Double(block) * 100 + 1 + 10]
            blocks += [block, block]
        }
        let together = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                                  blocks: blocks, resamples: 2000, seed: 5)
        XCTAssertEqual(together, BenchmarkAnalysis.Interval(point: 5, lower: 5, upper: 5))

        // Same pairs, each pair its own block: resamples can now be unbalanced, so the interval opens up.
        let separate = try BenchmarkAnalysis.pairedBlockBootstrap(baseline: baseline, candidate: candidate,
                                                                  blocks: Array(0..<20), resamples: 2000, seed: 5)
        XCTAssertGreaterThan(separate!.upper, separate!.lower)
    }

    func test_bootstrap_invalidInput() throws {
        XCTAssertThrowsError(try BenchmarkAnalysis.pairedBlockBootstrap(baseline: [1, 2], candidate: [1],
                                                                        blocks: [0, 0], seed: 1)) { error in
            guard case .invalidInput = error as? BenchmarkAnalysis.Failure else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try BenchmarkAnalysis.pairedBlockBootstrap(baseline: [1, 2], candidate: [1, 2],
                                                                        blocks: [0], seed: 1)) { error in
            guard case .invalidInput = error as? BenchmarkAnalysis.Failure else { return XCTFail("\(error)") }
        }
        XCTAssertNil(try BenchmarkAnalysis.pairedBlockBootstrap(baseline: [], candidate: [], blocks: [], seed: 1))
    }

    // MARK: 4. One-sided bounds

    private func constantShift(_ shift: Double, count: Int = 10) -> (baseline: [Double], candidate: [Double], blocks: [Int]) {
        let baseline = (0..<count).map { 100 + Double($0) * 3 }
        return (baseline, baseline.map { $0 + shift }, (0..<count).map { $0 / 2 })
    }

    func test_oneSidedBounds_regressionUpper_fixture() throws {
        let data = constantShift(3)   // candidate - baseline = +3 for every pair
        func bounds(_ threshold: Double, floor: Double = 1) throws -> BenchmarkAnalysis.OneSidedBounds {
            return try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
                baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
                regressionThresholdMs: threshold, improvementThresholdMs: 100, msFloor: floor,
                resamples: 500, seed: 3))
        }
        let passing = try bounds(5)
        XCTAssertEqual(passing.regressionUpper, 3)
        XCTAssertTrue(passing.regressionPasses)
        XCTAssertEqual(passing.effectiveRegressionThreshold, 5)
        XCTAssertFalse(try bounds(2.9).regressionPasses)
        XCTAssertTrue(try bounds(3).regressionPasses)         // exactly at the threshold: <= is inclusive
    }

    func test_oneSidedBounds_improvementLower_fixture() throws {
        let data = constantShift(-4)  // baseline - candidate = +4 for every pair
        func bounds(_ threshold: Double, floor: Double = 1) throws -> BenchmarkAnalysis.OneSidedBounds {
            return try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
                baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
                regressionThresholdMs: 100, improvementThresholdMs: threshold, msFloor: floor,
                resamples: 500, seed: 3))
        }
        let passing = try bounds(3)
        XCTAssertEqual(passing.improvementLower, 4)
        XCTAssertTrue(passing.improvementPasses)
        XCTAssertEqual(passing.effectiveImprovementThreshold, 3)
        XCTAssertTrue(try bounds(4).improvementPasses)         // exactly at the threshold: >= is inclusive
        XCTAssertFalse(try bounds(4.1).improvementPasses)
        // A candidate that is slower can never pass improvement, and the lower bound has the right sign.
        let slower = constantShift(4)
        let result = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: slower.baseline, candidate: slower.candidate, blocks: slower.blocks,
            regressionThresholdMs: 100, improvementThresholdMs: 1, resamples: 500, seed: 3))
        XCTAssertEqual(result.improvementLower, -4)
        XCTAssertFalse(result.improvementPasses)
    }

    func test_oneSidedBounds_floorRaisesSmallThresholds() throws {
        let regress = constantShift(0.8)
        let regression = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: regress.baseline, candidate: regress.candidate, blocks: regress.blocks,
            regressionThresholdMs: 0.5, improvementThresholdMs: 0.5, resamples: 200, seed: 1))
        XCTAssertEqual(regression.effectiveRegressionThreshold, 1)   // default floor 1 ms raises 0.5
        XCTAssertTrue(regression.regressionPasses)                   // 0.8 <= 1, would fail against 0.5

        let improve = constantShift(-0.9)
        let improvement = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: improve.baseline, candidate: improve.candidate, blocks: improve.blocks,
            regressionThresholdMs: 0.5, improvementThresholdMs: 0.5, resamples: 200, seed: 1))
        XCTAssertEqual(improvement.effectiveImprovementThreshold, 1)
        XCTAssertFalse(improvement.improvementPasses)                // 0.9 >= 1 is false, would pass against 0.5

        let explicit = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: improve.baseline, candidate: improve.candidate, blocks: improve.blocks,
            regressionThresholdMs: 0.5, improvementThresholdMs: 0.5, msFloor: 0.25, resamples: 200, seed: 1))
        XCTAssertEqual(explicit.effectiveImprovementThreshold, 0.5)  // a floor below the threshold changes nothing
        XCTAssertTrue(explicit.improvementPasses)
        // A threshold above the floor is untouched.
        XCTAssertEqual(try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: improve.baseline, candidate: improve.candidate, blocks: improve.blocks,
            regressionThresholdMs: 7, improvementThresholdMs: 1.5, resamples: 200, seed: 1))
            .effectiveRegressionThreshold, 7)
    }

    func test_oneSidedBounds_sameSeedGivesMirrorImage() throws {
        // Deltas {0,10} kept together in blocks: the regression CI is exactly 5, the improvement CI exactly -5.
        var baseline = [Double]()
        var candidate = [Double]()
        var blocks = [Int]()
        for block in 0..<6 {
            baseline += [50, 60]
            candidate += [50, 70]
            blocks += [block, block]
        }
        let result = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: baseline, candidate: candidate, blocks: blocks,
            regressionThresholdMs: 5, improvementThresholdMs: 5, resamples: 300, seed: 11))
        XCTAssertEqual(result.regressionUpper, 5)
        XCTAssertEqual(result.improvementLower, -5)
        XCTAssertTrue(result.regressionPasses)
        XCTAssertFalse(result.improvementPasses)
    }

    private func noisyFixture(sign: Double) -> (baseline: [Double], candidate: [Double], blocks: [Int]) {
        let baseline: [Double] = (0..<40).map { 100 + Double(($0 * 7) % 11) }
        let deltas: [Double] = (0..<40).map { sign * Double(($0 * 37) % 101) / 4 }
        return (baseline, zip(baseline, deltas).map { $0 + $1 }, Array(0..<40))
    }

    func test_oneSidedBounds_regressionUsesUpperEnd_noisyDeltas() throws {
        let data = noisyFixture(sign: 1)   // candidate - baseline: point 12.125, CI [8.625, 16.25]
        let ci = try XCTUnwrap(BenchmarkAnalysis.pairedBlockBootstrap(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks, seed: 42))
        XCTAssertLessThan(ci.lower, ci.point)
        XCTAssertLessThan(ci.point, ci.upper)
        // 14 sits strictly between lower and upper: the upper bound fails it, the lower bound would pass it.
        let bounds = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
            regressionThresholdMs: 14, improvementThresholdMs: 14, seed: 42))
        XCTAssertEqual(bounds.regressionUpper, ci.upper)
        XCTAssertEqual(bounds.regressionUpper, 16.25)
        XCTAssertGreaterThan(bounds.regressionUpper, ci.point)
        XCTAssertFalse(bounds.regressionPasses)
        XCTAssertTrue(ci.lower <= 14)
        let loose = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
            regressionThresholdMs: 16.25, improvementThresholdMs: 14, seed: 42))
        XCTAssertTrue(loose.regressionPasses)
    }

    func test_oneSidedBounds_improvementUsesLowerEnd_noisyDeltas() throws {
        let data = noisyFixture(sign: -1)  // baseline - candidate: point 12.125, CI [8.625, 16.25]
        let ci = try XCTUnwrap(BenchmarkAnalysis.pairedBlockBootstrap(
            baseline: data.candidate, candidate: data.baseline, blocks: data.blocks, seed: 42))
        XCTAssertLessThan(ci.lower, ci.point)
        XCTAssertLessThan(ci.point, ci.upper)
        // 10 sits strictly between lower and upper: the lower bound fails it, the upper bound would pass it.
        let bounds = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
            regressionThresholdMs: 100, improvementThresholdMs: 10, seed: 42))
        XCTAssertEqual(bounds.improvementLower, ci.lower)
        XCTAssertEqual(bounds.improvementLower, 8.625)
        XCTAssertLessThan(bounds.improvementLower, ci.point)
        XCTAssertFalse(bounds.improvementPasses)
        XCTAssertTrue(ci.upper >= 10)
        let easier = try XCTUnwrap(BenchmarkAnalysis.oneSidedBounds(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
            regressionThresholdMs: 100, improvementThresholdMs: 8.625, seed: 42))
        XCTAssertTrue(easier.improvementPasses)
    }

    // MARK: 5, 6. Minimum runs and noisy baseline

    private func comparisonInputs(pairs: Int) -> (baseline: [Double], candidate: [Double], blocks: [Int]) {
        let baseline = (0..<pairs).map { 100 + Double($0 % 5) }
        return (baseline, baseline, (0..<pairs).map { $0 / 2 })
    }

    func test_minimumRuns_50() throws {
        func compare(_ pairs: Int) throws -> BenchmarkAnalysis.Comparison {
            let data = comparisonInputs(pairs: pairs)
            return try BenchmarkAnalysis.compare(
                baseline: data.baseline, candidate: data.candidate, blocks: data.blocks,
                regressionThresholdMs: 5, improvementThresholdMs: 5, maxHalfWidthPercent: 1000,
                resamples: 100, seed: 1)
        }
        let short = try compare(49)
        XCTAssertTrue(short.insufficientRuns)
        XCTAssertNil(short.bounds)
        XCTAssertNil(short.baselineAssessment)
        XCTAssertEqual(short.pairCount, 49)

        let enough = try compare(50)
        XCTAssertFalse(enough.insufficientRuns)
        XCTAssertNotNil(enough.bounds)
        XCTAssertEqual(enough.baselineAssessment?.rejected, false)

        let data = comparisonInputs(pairs: 10)
        let custom = try BenchmarkAnalysis.compare(
            baseline: data.baseline, candidate: data.candidate, blocks: data.blocks, regressionThresholdMs: 5,
            improvementThresholdMs: 5, maxHalfWidthPercent: 1000, minRuns: 10, resamples: 100, seed: 1)
        XCTAssertFalse(custom.insufficientRuns)
        XCTAssertTrue(BenchmarkAnalysis.hasMinimumRuns(50))
        XCTAssertFalse(BenchmarkAnalysis.hasMinimumRuns(49))
    }

    func test_noisyBaseline_rejected() throws {
        // Half-width exactly 10 against a median of 100 is exactly 10 percent: not rejected.
        let atLimit = BenchmarkAnalysis.assessBaseline(
            interval: BenchmarkAnalysis.Interval(point: 100, lower: 90, upper: 110),
            baselineMedian: 100, maxHalfWidthPercent: 10)
        XCTAssertFalse(atLimit.rejected)
        XCTAssertNil(atLimit.reason)
        XCTAssertEqual(atLimit.halfWidthPercent, 10)

        let above = BenchmarkAnalysis.assessBaseline(
            interval: BenchmarkAnalysis.Interval(point: 100, lower: 89.999999, upper: 110),
            baselineMedian: 100, maxHalfWidthPercent: 10)
        XCTAssertTrue(above.rejected)
        XCTAssertTrue(above.reason?.contains("re-collect") == true)

        // The same interval against a larger limit passes, so the limit is a real parameter.
        XCTAssertFalse(BenchmarkAnalysis.assessBaseline(
            interval: BenchmarkAnalysis.Interval(point: 100, lower: 89.999999, upper: 110),
            baselineMedian: 100, maxHalfWidthPercent: 11).rejected)

        // End to end: a wildly alternating baseline is rejected and gets no verdict.
        let baseline = (0..<50).map { $0 % 2 == 0 ? 10.0 : 1000.0 }
        let blocks = (0..<50).map { $0 / 2 }
        // Each pair its own block, so resamples can be lopsided (a paired block of 10 and 1000 would not vary).
        let noisy = try BenchmarkAnalysis.compare(
            baseline: baseline, candidate: baseline, blocks: Array(0..<50), regressionThresholdMs: 5,
            improvementThresholdMs: 5, maxHalfWidthPercent: 5, resamples: 300, seed: 1)
        XCTAssertFalse(noisy.insufficientRuns)
        XCTAssertEqual(noisy.baselineAssessment?.rejected, true)
        XCTAssertNil(noisy.bounds)

        // A constant baseline has half-width 0: not rejected even at a 0 percent limit.
        let constant = Array(repeating: 100.0, count: 50)
        let calm = try BenchmarkAnalysis.compare(
            baseline: constant, candidate: constant, blocks: blocks, regressionThresholdMs: 5,
            improvementThresholdMs: 5, maxHalfWidthPercent: 0, resamples: 300, seed: 1)
        XCTAssertEqual(calm.baselineAssessment?.rejected, false)
        XCTAssertNotNil(calm.bounds)
    }

    // MARK: 7. Thermal

    func test_thermal_nonNominalExcluded() throws {
        let rows = [
            warm(0),
            warm(1, ["thermalStateBefore": "fair"]),
            warm(2, ["thermalStateAfter": "serious"]),
            warm(3, ["thermalStateBefore": "critical", "thermalStateAfter": "unknown"]),
            warm(4, ["thermalStateAfter": ""]),
            warm(5)
        ]
        let split = BenchmarkAnalysis.splitByThermal(try runs(rows))
        XCTAssertEqual(split.nominal.map { $0.runIndex }, [0, 5])
        XCTAssertEqual(split.excluded.count, 4)
        XCTAssertEqual(split.excluded.map { $0.runIndex }, [1, 2, 3, 4])
        XCTAssertEqual(split.excluded[0].before, "fair")
        XCTAssertEqual(split.excluded[0].after, "nominal")
        XCTAssertEqual(split.excluded[1].before, "nominal")
        XCTAssertEqual(split.excluded[1].after, "serious")
        XCTAssertEqual(split.excluded[2].before, "critical")
        XCTAssertEqual(split.excluded[2].after, "unknown")
        XCTAssertNil(split.excluded[3].after)
    }

    // MARK: 8. Drift

    func test_drift_regressionSlope() throws {
        // One run every 600 s; total = 100 ms + 2 ms per hour elapsed, so the slope is 2 ms/hour.
        var rows = [[String: String]]()
        for i in 0..<7 {
            let hours = Double(i) / 6.0
            let total = 100 + 2 * hours
            rows.append(warm(i, stagesMs: [10, 10, 10, 10, 10, 10, total - 60],
                             wallClock: wall(secondsAfterBase: i * 600)))
        }
        let drift = try XCTUnwrap(BenchmarkAnalysis.drift(runs: runs(rows)))
        XCTAssertEqual(drift.slopeMsPerHour, 2, accuracy: 1e-3)
        XCTAssertEqual(drift.count, 7)

        // The sign follows the data.
        var falling = [[String: String]]()
        for i in 0..<4 {
            falling.append(warm(i, stagesMs: [10, 10, 10, 10, 10, 10, 40 - Double(i) * 6],
                                wallClock: wall(secondsAfterBase: i * 1800)))
        }
        // totals 100, 94, 88, 82 each 0.5 h apart: -12 ms per hour
        XCTAssertEqual(try XCTUnwrap(BenchmarkAnalysis.drift(runs: runs(falling))).slopeMsPerHour, -12, accuracy: 1e-3)

        // Not enough distinct times.
        XCTAssertNil(BenchmarkAnalysis.drift(runs: try runs([warm(0)])))
        XCTAssertNil(BenchmarkAnalysis.drift(runs: try runs([warm(0), warm(1)])))   // same wall clock
        XCTAssertNil(BenchmarkAnalysis.drift(runs: []))
        // A run without a wall clock does not count.
        XCTAssertNil(BenchmarkAnalysis.drift(runs: try runs([warm(0), warm(1, wallClock: "")])))
        let withMissing = try runs([warm(0, wallClock: wall(secondsAfterBase: 0)), warm(1, wallClock: ""),
                                    warm(2, wallClock: wall(secondsAfterBase: 3600))])
        XCTAssertEqual(BenchmarkAnalysis.drift(runs: withMissing)?.count, 2)
    }

    // MARK: 9. Logging gap

    func test_loggingGap_perScenario() {
        let both = BenchmarkAnalysis.loggingGap(scenario: "A", sha: "s1", onTotals: [10, 20, 30], offTotals: [5, 15])
        XCTAssertEqual(both.onMedianMs, 20)
        XCTAssertEqual(both.offMedianMs, 10)
        XCTAssertEqual(both.gapMs, 10)

        let negative = BenchmarkAnalysis.loggingGap(scenario: "A", sha: "s1", onTotals: [4], offTotals: [9])
        XCTAssertEqual(negative.gapMs, -5)

        let noOff = BenchmarkAnalysis.loggingGap(scenario: "B", sha: "s1", onTotals: [10, 20], offTotals: [])
        XCTAssertEqual(noOff.onMedianMs, 15)
        XCTAssertNil(noOff.offMedianMs)
        XCTAssertNil(noOff.gapMs)

        let noOn = BenchmarkAnalysis.loggingGap(scenario: "B", sha: "s1", onTotals: [], offTotals: [3])
        XCTAssertNil(noOn.onMedianMs)
        XCTAssertEqual(noOn.offMedianMs, 3)
        XCTAssertNil(noOn.gapMs)
    }

    // MARK: 10. R13

    private func complete(_ count: Int, scenario: String = "A") -> [[String: String]] {
        return (0..<count).map { warm($0, scenario: scenario) }
    }

    func test_r13_missingMark_failsRun() throws {
        var rows = complete(3)
        var missingT7 = warm(3)
        missingT7["T7"] = ""
        var missingTwo = warm(4)
        missingTwo["T10"] = ""
        missingTwo["T5"] = ""
        rows += [missingT7, missingTwo]
        let result = BenchmarkAnalysis.checkR13(runs: try runs(rows))
        XCTAssertEqual(result.failedRuns.count, 2)
        XCTAssertEqual(result.failedRuns[0].runIndex, 3)
        XCTAssertEqual(result.failedRuns[0].chain, .warm)
        XCTAssertEqual(result.failedRuns[0].missing, ["T7"])
        XCTAssertEqual(result.failedRuns[1].runIndex, 4)
        XCTAssertEqual(result.failedRuns[1].missing, ["T5", "T10"])   // required-mark order, not column order
        XCTAssertEqual(result.warm?.runCount, 5)
        XCTAssertEqual(result.warm?.completeRunCount, 3)
        XCTAssertNil(result.cold)
        XCTAssertFalse(result.passes)

        // Every warm required mark, taken away one at a time, fails the run and is named.
        for mark in ["T0", "T1", "T2", "T3", "T5", "T7", "T8", "T10", "T11"] {
            var row = warm(0)
            row[mark] = ""
            let one = BenchmarkAnalysis.checkR13(runs: try runs([row]))
            XCTAssertEqual(one.failedRuns.map { $0.missing }, [[mark]], "mark \(mark)")
        }

        let allGood = BenchmarkAnalysis.checkR13(runs: try runs(complete(3)))
        XCTAssertTrue(allGood.failedRuns.isEmpty)
        XCTAssertTrue(allGood.passes)
        XCTAssertEqual(allGood.warm?.completeRunCount, 3)
        XCTAssertEqual(allGood.warm?.stages.map { $0.name }, ["T0->T1", "T1->T2", "T2->T3", "T3->T5", "T5->T7",
                                                               "T7->T8", "T8->T11"])
        XCTAssertEqual(allGood.warm?.markCount, 8)
        XCTAssertEqual(allGood.warm?.medianTotalMs, 70)
        XCTAssertEqual(allGood.warm?.sumOfStageMedians, 70)
        XCTAssertEqual(allGood.warm?.toleranceMs, 8)    // max(10% of 70 = 7, 8 marks * 1 ms)
    }

    func test_r13_coldChain() throws {
        var missingMySegments = cold(2)
        missingMySegments["coldEnd_mySegmentsUpdated"] = ""
        let rows = [cold(0), cold(1), missingMySegments, cold(3, ["T8": "", "T10": "", "T7": ""])]
        let result = BenchmarkAnalysis.checkR13(runs: try runs(rows))
        XCTAssertNil(result.warm)
        XCTAssertEqual(result.failedRuns.count, 1)
        XCTAssertEqual(result.failedRuns[0].runIndex, 2)
        XCTAssertEqual(result.failedRuns[0].chain, .cold)
        XCTAssertEqual(result.failedRuns[0].missing, ["coldEnd_mySegmentsUpdated"])
        XCTAssertEqual(result.cold?.runCount, 4)
        XCTAssertEqual(result.cold?.completeRunCount, 3)   // the row without T7/T8/T10 passes on the cold chain
        XCTAssertEqual(result.cold?.stages.map { $0.name }, [
            "T0->T1", "T1->T2", "T2->T3", "T3->T5", "T5->coldEnd_splitsUpdated",
            "coldEnd_splitsUpdated->coldEnd_mySegmentsUpdated",
            "coldEnd_mySegmentsUpdated->coldEnd_myLargeSegmentsUpdated",
            "coldEnd_myLargeSegmentsUpdated->T11"])
        XCTAssertEqual(result.cold?.markCount, 9)
        XCTAssertEqual(result.cold?.medianTotalMs, 80)
        XCTAssertFalse(result.passes)   // the failed run fails R13 overall

        // Cold marks are ordered by value, not by name.
        let reordered = BenchmarkAnalysis.checkR13(runs: try runs([
            cold(0, coldOrder: ["coldEnd_myLargeSegmentsUpdated", "coldEnd_splitsUpdated",
                                "coldEnd_mySegmentsUpdated"])]))
        XCTAssertEqual(reordered.cold?.stages.map { $0.name }, [
            "T0->T1", "T1->T2", "T2->T3", "T3->T5", "T5->coldEnd_myLargeSegmentsUpdated",
            "coldEnd_myLargeSegmentsUpdated->coldEnd_splitsUpdated",
            "coldEnd_splitsUpdated->coldEnd_mySegmentsUpdated",
            "coldEnd_mySegmentsUpdated->T11"])
        XCTAssertTrue(reordered.passes)

        // A cold row that still carries T7/T8/T10 is judged on the cold chain only.
        XCTAssertEqual(BenchmarkAnalysis.checkR13(runs: try runs([cold(0, ["T7": "1", "T8": "2", "T10": "3"])]))
            .cold?.completeRunCount, 1)
    }

    func test_r13_chainSelection() throws {
        // Scenario D always uses the cold chain, even when cacheHit is true or missing.
        for hit in ["true", ""] {
            let result = BenchmarkAnalysis.checkR13(runs: try runs([cold(0, scenario: "D", cacheHit: hit)]))
            XCTAssertNil(result.warm, "cacheHit=\(hit)")
            XCTAssertEqual(result.cold?.completeRunCount, 1, "cacheHit=\(hit)")
        }
        // A missing cacheHit outside scenario D is a warm run.
        var unknown = warm(0)
        unknown["cacheHit"] = ""
        XCTAssertEqual(BenchmarkAnalysis.checkR13(runs: try runs([unknown])).warm?.runCount, 1)
        // Mixed groups are reported per chain.
        let mixed = BenchmarkAnalysis.checkR13(runs: try runs([warm(0), cold(1), warm(2), cold(3)]))
        XCTAssertEqual(mixed.warm?.runCount, 2)
        XCTAssertEqual(mixed.cold?.runCount, 2)
        XCTAssertTrue(mixed.passes)
        // A warm-looking row that lacks coldEnd marks fails in scenario D.
        let dWarm = BenchmarkAnalysis.checkR13(runs: try runs([warm(0, scenario: "D")]))
        XCTAssertEqual(dWarm.failedRuns.first?.chain, .cold)
        XCTAssertEqual(dWarm.failedRuns.first?.missing, ["coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated",
                                                         "coldEnd_myLargeSegmentsUpdated"])
    }

    func test_r13_branchChoice() throws {
        // T10 later than T8: the chain runs T3 -> T10 -> T11 and skips T5, T7, T8.
        var t10Later = warm(0)
        let t8 = UInt64(t10Later["T8"]!)!
        t10Later["T10"] = String(t8 + ns(5))   // T11 is T8 + 10 ms
        let later = BenchmarkAnalysis.checkR13(runs: try runs([t10Later]))
        XCTAssertEqual(later.warm?.stages.map { $0.name }, ["T0->T1", "T1->T2", "T2->T3", "T3->T10", "T10->T11"])
        XCTAssertEqual(later.warm?.stages.map { $0.medianMs }, [10, 10, 10, 35, 5])
        XCTAssertEqual(later.warm?.markCount, 6)
        XCTAssertEqual(later.warm?.toleranceMs, 7)   // max(10% of 70 = 7, 6 marks)

        // T8 later: the chain runs through T5, T7, T8.
        var t8Later = warm(0)
        t8Later["T10"] = String(t8 - ns(5))
        let earlier = BenchmarkAnalysis.checkR13(runs: try runs([t8Later]))
        XCTAssertEqual(earlier.warm?.stages.map { $0.name }, ["T0->T1", "T1->T2", "T2->T3", "T3->T5", "T5->T7",
                                                                "T7->T8", "T8->T11"])
        // Equal: the splits branch.
        XCTAssertEqual(BenchmarkAnalysis.checkR13(runs: try runs([warm(0)])).warm?.markCount, 8)

        // Mixed branches: stage medians are taken over the runs where the stage exists.
        let mixed = BenchmarkAnalysis.checkR13(runs: try runs([warm(0), warm(1), t10Later]))
        let byName = Dictionary(uniqueKeysWithValues: (mixed.warm?.stages ?? []).map { ($0.name, $0.medianMs) })
        XCTAssertEqual(byName["T8->T11"], 10)     // present in two runs
        XCTAssertEqual(byName["T3->T10"], 35)     // present in one run
        XCTAssertEqual(byName["T0->T1"], 10)
    }

    func test_r13_toleranceBoundaries() throws {
        XCTAssertEqual(BenchmarkAnalysis.r13Tolerance(medianTotalMs: 1000, markCount: 8), 100)
        XCTAssertEqual(BenchmarkAnalysis.r13Tolerance(medianTotalMs: 10, markCount: 8), 8)
        XCTAssertEqual(BenchmarkAnalysis.r13Tolerance(medianTotalMs: 80, markCount: 8), 8)
        XCTAssertEqual(BenchmarkAnalysis.r13Tolerance(medianTotalMs: 90, markCount: 8), 9)
        XCTAssertEqual(BenchmarkAnalysis.r13Tolerance(medianTotalMs: 200, markCount: 9), 20)

        // Three runs whose per-stage medians do not add up to the median total.
        // The stage deltas sit in T0>T1 (index 0) and T8>T11 (index 6); every other stage is 0 ms.
        func result(_ pairs: [(Double, Double)]) throws -> BenchmarkAnalysis.R13Result {
            let rows = pairs.enumerated().map { index, pair in
                warm(index, stagesMs: [pair.0, 0, 0, 0, 0, 0, pair.1])
            }
            return BenchmarkAnalysis.checkR13(runs: try runs(rows))
        }
        // 10% arm: totals 1000, 900 (or 899), 1000 -> median 1000, stage medians sum to 900 (899).
        let insideTenPercent = try XCTUnwrap(result([(0, 1000), (450, 450), (1000, 0)]).warm)
        XCTAssertEqual(insideTenPercent.medianTotalMs, 1000)
        XCTAssertEqual(insideTenPercent.sumOfStageMedians, 900)
        XCTAssertEqual(insideTenPercent.toleranceMs, 100)
        XCTAssertTrue(insideTenPercent.passes)          // |900 - 1000| = 100 <= 100
        let outsideTenPercent = try XCTUnwrap(result([(0, 1000), (449.5, 449.5), (1000, 0)]).warm)
        XCTAssertEqual(outsideTenPercent.sumOfStageMedians, 899)
        XCTAssertFalse(outsideTenPercent.passes)        // 101 > 100

        // Per-mark arm: median total 10 ms, 8 marks -> tolerance 8 ms.
        let insideMarkArm = try XCTUnwrap(result([(0, 10), (1, 1), (10, 0)]).warm)
        XCTAssertEqual(insideMarkArm.toleranceMs, 8)
        XCTAssertEqual(insideMarkArm.sumOfStageMedians, 2)
        XCTAssertTrue(insideMarkArm.passes)             // |2 - 10| = 8 <= 8
        let outsideMarkArm = try XCTUnwrap(result([(0, 10), (0.5, 0.5), (10, 0)]).warm)
        XCTAssertEqual(outsideMarkArm.sumOfStageMedians, 1)
        XCTAssertFalse(outsideMarkArm.passes)           // 9 > 8
        // Overall R13 follows the chain verdict.
        XCTAssertFalse(try result([(0, 10), (0.5, 0.5), (10, 0)]).passes)
        XCTAssertTrue(try result([(0, 10), (1, 1), (10, 0)]).passes)
    }

    // MARK: 11. Stage shares

    func test_stageShares_relativeAndUnresolved() throws {
        let stages: [Double] = [0.5, 1.0, 1.5, 2, 3, 4, 8]    // total 20 ms
        let rows = (0..<3).map { warm($0, stagesMs: stages) }
        let chain = try XCTUnwrap(BenchmarkAnalysis.checkR13(runs: try runs(rows)).warm)
        XCTAssertEqual(chain.medianTotalMs, 20)
        let shares = chain.stages.map { $0.share ?? -1 }
        for (actual, expected) in zip(shares, [0.025, 0.05, 0.075, 0.1, 0.15, 0.2, 0.4]) {
            XCTAssertEqual(actual, expected, accuracy: 1e-12)
        }
        XCTAssertEqual(chain.stages.map { $0.unresolved }, [true, false, false, false, false, false, false])
        XCTAssertEqual(chain.stages[1].medianMs, 1.0)   // exactly 1 ms is resolved

        // Just under 1 ms is unresolved.
        let justUnder = (0..<3).map { warm($0, stagesMs: [0.999999, 10, 10, 10, 10, 10, 10]) }
        let under = try XCTUnwrap(BenchmarkAnalysis.checkR13(runs: try runs(justUnder)).warm)
        XCTAssertTrue(under.stages[0].unresolved)
        XCTAssertFalse(under.stages[1].unresolved)
        // Shares are relative: they sum to about 1 for a chain whose stages add up.
        XCTAssertEqual(shares.reduce(0, +), 1, accuracy: 1e-12)
    }

    // MARK: 12. Decode share

    func test_decodeShare_median() throws {
        func decodeRow(_ index: Int, totalMs: Double, _ extra: [String: String]) -> [String: String] {
            var fields = warm(index, stagesMs: [0, 0, 0, 0, 0, 0, totalMs])
            for column in ["T6_loadLocal_start", "T6_loadLocal_end"] { fields[column] = "" }
            return fields.merging(extra) { _, new in new }
        }
        func at(_ ms: Double) -> String { String(baseNanos + ns(ms)) }
        let rows = [
            // 10 ms (filter) + 20 ms (forceParsing); loadLocal has a start but no end, so it is ignored: 30/100.
            decodeRow(0, totalMs: 100, [
                "T6_filterSplitsInCache_start": at(1), "T6_filterSplitsInCache_end": at(11),
                "T6_forceParsing_start": at(20), "T6_forceParsing_end": at(40), "T6_loadLocal_start": at(50)]),
            // Three sites, 5 ms each: 15/60 = 0.25.
            decodeRow(1, totalMs: 60, [
                "T6_filterSplitsInCache_start": at(1), "T6_filterSplitsInCache_end": at(6),
                "T6_forceParsing_start": at(10), "T6_forceParsing_end": at(15),
                "T6_loadLocal_start": at(20), "T6_loadLocal_end": at(25)]),
            // No decode marks at all: share 0.
            decodeRow(2, totalMs: 50, [:]),
            // No T11: no share, and not counted as 0.
            decodeRow(3, totalMs: 50, ["T11": "", "T6_forceParsing_start": at(1), "T6_forceParsing_end": at(2)])
        ]
        let parsed = try runs(rows)
        let shares = parsed.map { BenchmarkAnalysis.decodeShare($0) }
        XCTAssertEqual(try XCTUnwrap(shares[0]), 0.3, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(shares[1]), 0.25, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(shares[2]), 0, accuracy: 1e-12)
        XCTAssertNil(shares[3])
        XCTAssertEqual(try XCTUnwrap(BenchmarkAnalysis.decodeShareMedian(runs: parsed)), 0.25, accuracy: 1e-12)
        XCTAssertNil(BenchmarkAnalysis.decodeShareMedian(runs: []))
    }

    // MARK: 13. Run classes

    func test_runClass_allFiveLabels() throws {
        func row(_ index: Int, _ extra: [String: String]) -> [String: String] { warm(index, extra) }
        let rows: [[String: String]] = [
            row(0, [:]),                                                                        // warmCacheHit
            row(1, ["decodeCount": "0"]),                                                       // warmCacheHit
            row(2, ["flagSpecHasChanged": "true"]),                                             // flagSpecOrFilterChange
            row(3, ["filterHasChanged": "true"]),                                               // flagSpecOrFilterChange
            row(4, ["forceParsingRan": "true"]),                                                // firstRunForceParsing
            row(5, ["cacheHit": "false"]),                                                      // cacheMiss
            row(6, ["decodeCount": "2"]),                                                       // moreThanOneDecode
            row(7, ["cacheHit": ""]),                                                           // unknown
            // Multi-match rows prove the fixed order.
            row(8, ["flagSpecHasChanged": "true", "forceParsingRan": "true", "decodeCount": "3"]),  // 2 beats 3, 5
            row(9, ["cacheHit": "false", "forceParsingRan": "true"]),                           // 3 beats 4
            row(10, ["cacheHit": "false", "decodeCount": "2"]),                                 // 4 beats 5
            row(11, ["forceParsingRan": "true", "decodeCount": "2"]),                           // 3 beats 5
            row(12, ["cacheHit": "false", "flagSpecHasChanged": "true"]),                       // 2 beats 4
            row(13, ["cacheHit": "true", "decodeCount": "2", "flagSpecHasChanged": ""]),        // 5: missing flag is not true
            row(14, ["cacheHit": "", "decodeCount": "2"]),                                      // 5 even when cacheHit missing
            row(15, ["cacheHit": "", "forceParsingRan": "true"]),                               // 3 even when cacheHit missing
            row(16, ["decodeCount": ""]),                                                       // unknown: decodeCount missing
            row(17, ["flagSpecHasChanged": "", "filterHasChanged": ""])                         // warmCacheHit: missing flags
        ]
        let classes = try runs(rows).map { BenchmarkAnalysis.runClass($0) }
        let expected: [BenchmarkAnalysis.RunClass] = [
            .warmCacheHit, .warmCacheHit, .flagSpecOrFilterChange, .flagSpecOrFilterChange, .firstRunForceParsing,
            .cacheMiss, .moreThanOneDecode, .unknown,
            .flagSpecOrFilterChange, .firstRunForceParsing, .cacheMiss, .firstRunForceParsing,
            .flagSpecOrFilterChange, .moreThanOneDecode, .moreThanOneDecode, .firstRunForceParsing,
            .unknown, .warmCacheHit
        ]
        XCTAssertEqual(classes, expected)
        XCTAssertEqual(BenchmarkAnalysis.RunClass.allCases.map { $0.rawValue }, [
            "warmCacheHit", "flagSpecOrFilterChange", "firstRunForceParsing", "cacheMiss", "moreThanOneDecode",
            "unknown"])
    }

    func test_runClass_unknownIsKeptInReport() throws {
        let rows = [warm(0), warm(1, ["cacheHit": ""]), warm(2, ["installState": "first"])]
        let reports = BenchmarkAnalysisReport.build(runs: try runs(rows))
        XCTAssertEqual(reports.count, 1)
        let report = reports[0]
        XCTAssertEqual(report.entries.map { $0.runIndex }, [0, 1, 2])
        XCTAssertEqual(report.entries.map { $0.runClass }, [.warmCacheHit, .unknown, .warmCacheHit])
        XCTAssertEqual(report.entries.map { $0.firstInstall }, [false, false, true])
        XCTAssertEqual(report.nonPrimary.map { $0.runIndex }, [1, 2])
        XCTAssertEqual(report.nonPrimary[0].reasons, ["class:unknown"])
        XCTAssertEqual(report.nonPrimary[1].reasons, ["firstInstall"])
        XCTAssertEqual(report.primaryCount, 1)
        let text = report.summary()
        XCTAssertTrue(text.contains("run 1: unknown"), text)
        XCTAssertTrue(text.contains("run 0: warmCacheHit"), text)
        XCTAssertTrue(text.contains("run 2: warmCacheHit firstInstall"), text)
    }

    // MARK: 14. Report assembly

    func test_report_endToEnd() throws {
        var rows = [[String: String]]()
        // Scenario A, logging-off, sha s1: 60 runs, total 100 + i ms, one run per minute.
        for i in 0..<60 {
            var extra = [String: String]()
            if i == 3 { extra["thermalStateBefore"] = "fair" }
            if i == 7 { extra["installState"] = "first" }
            if i == 11 { extra["cacheHit"] = "false" }
            rows.append(warm(i, stagesMs: [10, 10, 10, 10, 10, 10, 40 + Double(i)], scenario: "A",
                             wallClock: wall(secondsAfterBase: i * 60), extra))
        }
        // Scenario A, logging-on: 60 clean runs, total 200 + i ms.
        for i in 0..<60 {
            rows.append(warm(i, stagesMs: [10, 10, 10, 10, 10, 10, 140 + Double(i)], scenario: "A", build: "logging-on",
                             wallClock: wall(secondsAfterBase: i * 60)))
        }
        // Scenario B, logging-off: 49 clean runs, total 50 + i ms.
        for i in 0..<49 {
            rows.append(warm(i, stagesMs: [5, 5, 5, 5, 5, 5, 20 + Double(i)], scenario: "B",
                             wallClock: wall(secondsAfterBase: i * 60)))
        }
        let reports = BenchmarkAnalysisReport.build(runs: try runs(rows))
        XCTAssertEqual(reports.map { "\($0.scenario)/\($0.buildVariant)" },
                       ["A/logging-off", "A/logging-on", "B/logging-off"])

        let off = reports[0]
        XCTAssertEqual(off.totalRuns, 60)
        XCTAssertEqual(off.primaryCount, 57)               // runs 3 (thermal), 7 (first install), 11 (cache miss) out
        XCTAssertEqual(off.thermalExcludedCount, 1)
        XCTAssertEqual(off.thermalExclusions.map { $0.runIndex }, [3])
        XCTAssertEqual(off.nonPrimary.map { $0.runIndex }, [3, 7, 11])
        XCTAssertEqual(off.nonPrimary.map { $0.reasons }, [["thermal:fair/nominal"], ["firstInstall"], ["class:cacheMiss"]])
        XCTAssertFalse(off.insufficientRuns)
        let stats = try XCTUnwrap(off.stats)
        XCTAssertEqual(stats.count, 57)
        XCTAssertEqual(stats.median, 131)                  // 29th of 57 totals 100...159 without 103, 107, 111
        XCTAssertEqual(stats.p90, 154)                     // ceil(0.9 * 57) = 52nd
        XCTAssertEqual(stats.min, 100)
        XCTAssertEqual(stats.max, 159)
        XCTAssertEqual(try XCTUnwrap(off.decodeShareMedian), 10.0 / 131.0, accuracy: 1e-12)
        let drift = try XCTUnwrap(off.drift)
        XCTAssertEqual(drift.count, 57)
        XCTAssertEqual(drift.slopeMsPerHour, 60, accuracy: 1e-6)    // +1 ms per 60 s
        XCTAssertEqual(off.r13.failedRuns.map { $0.runIndex }, [11])   // the cache-miss row has no coldEnd marks
        XCTAssertEqual(off.r13.warm?.completeRunCount, 59)

        let on = reports[1]
        XCTAssertEqual(on.primaryCount, 60)
        XCTAssertEqual(on.thermalExcludedCount, 0)
        XCTAssertTrue(on.nonPrimary.isEmpty)
        XCTAssertEqual(on.stats?.median, 229.5)

        let small = reports[2]
        XCTAssertEqual(small.primaryCount, 49)
        XCTAssertTrue(small.insufficientRuns)
        XCTAssertEqual(small.stats?.median, 74)            // 50...98, 25th value
        let custom = BenchmarkAnalysisReport.build(runs: try runs(rows), minRuns: 49)
        XCTAssertFalse(custom[2].insufficientRuns)

        let gaps = BenchmarkAnalysisReport.loggingGaps(reports)
        XCTAssertEqual(gaps.map { "\($0.scenario)/\($0.sha)" }, ["A/s1", "B/s1"])
        XCTAssertEqual(gaps[0].gapMs, 98.5)                // 229.5 - 131
        XCTAssertEqual(gaps[0].onMedianMs, 229.5)
        XCTAssertEqual(gaps[0].offMedianMs, 131)
        XCTAssertNil(gaps[1].gapMs)

        let text = BenchmarkAnalysisReport.summary(reports)
        XCTAssertTrue(text.contains("run 3: warmCacheHit"), text)
        XCTAssertTrue(text.contains("run 11: cacheMiss"), text)
        XCTAssertTrue(text.contains("insufficientRuns"), text)
    }

    func test_report_groupsBySha() throws {
        let rows = [warm(0, sha: "base"), warm(1, sha: "cand"), warm(2, sha: "base")]
        let reports = BenchmarkAnalysisReport.build(runs: try runs(rows))
        XCTAssertEqual(reports.map { $0.sha }, ["base", "cand"])
        XCTAssertEqual(reports.map { $0.totalRuns }, [2, 1])
    }
}

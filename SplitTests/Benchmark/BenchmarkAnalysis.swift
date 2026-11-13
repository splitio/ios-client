//
//  BenchmarkAnalysis.swift
//  SplitTests
//
//  FME-22007 issue 29: pure analysis of the device benchmark CSV (spec 4.1 R11, R13 to R19, 6.2, 6.5).
//
//  Foundation only, deterministic: every resampling uses a seeded SplitMix64 generator, there is no Date(), no
//  unseeded random and no timing. The CSV text is parsed here against a copy of the column contract in
//  SplitBenchmark/BenchmarkCSVRow.swift (this target cannot import the benchmark target); a test pins the copy.
//

import Foundation

enum BenchmarkAnalysis {

    // MARK: Contract

    /// A copy of `BenchmarkCSVRow.columns`, in order.
    static let columns: [String] = [
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

    /// Columns that hold raw uptime nanoseconds.
    static let markColumns: [String] = [
        "T0", "T1", "T2", "T3", "T5",
        "T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end",
        "T6_forceParsing_start", "T6_forceParsing_end",
        "T6_loadLocal_start", "T6_loadLocal_end",
        "T7", "T8", "T10",
        "coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated", "coldEnd_myLargeSegmentsUpdated",
        "T11"
    ]

    static let defaultSeed: UInt64 = 0x5EED_0029
    static let defaultResamples = 10_000
    static let defaultMinRuns = 50
    static let defaultMsFloor = 1.0

    enum Failure: Error, Equatable {
        case headerMismatch
        /// `line` is the 1-based record number (the header is record 1).
        case malformedRow(line: Int)
        case invalidInput(String)
    }

    // MARK: 1. CSV parsing

    struct Row: Equatable {
        /// Only the non-empty fields; an empty field is a missing value.
        let values: [String: String]

        subscript(column: String) -> String? { return values[column] }
    }

    /// Splits RFC 4180 text into records of fields. Works on unicode scalars because "\r\n" is one Character.
    static func records(_ text: String) throws -> [[String]] {
        let scalars = Array(text.unicodeScalars)
        var records = [[String]]()
        var record = [String]()
        var field = String.UnicodeScalarView()
        var inQuotes = false
        var index = 0

        func endRecord() {
            record.append(String(field))
            field = String.UnicodeScalarView()
            if !(record.count == 1 && record[0].isEmpty) { records.append(record) }   // skip blank lines
            record = []
        }

        while index < scalars.count {
            let scalar = scalars[index]
            if inQuotes {
                if scalar == "\"" {
                    if index + 1 < scalars.count && scalars[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(scalar)
                }
            } else {
                switch scalar {
                case "\"":
                    inQuotes = true
                case ",":
                    record.append(String(field))
                    field = String.UnicodeScalarView()
                case "\n":
                    endRecord()
                case "\r":
                    if index + 1 < scalars.count && scalars[index + 1] == "\n" { index += 1 }
                    endRecord()
                default:
                    field.append(scalar)
                }
            }
            index += 1
        }
        if inQuotes { throw Failure.malformedRow(line: records.count + 1) }
        if !field.isEmpty || !record.isEmpty { endRecord() }
        return records
    }

    /// Parses the CSV text. The header must equal `columns`; every row must have exactly that many fields.
    static func parse(_ text: String) throws -> [Row] {
        let all = try records(text)
        guard let header = all.first, header == columns else { throw Failure.headerMismatch }
        var rows = [Row]()
        for (offset, record) in all.dropFirst().enumerated() {
            guard record.count == columns.count else { throw Failure.malformedRow(line: offset + 2) }
            var values = [String: String]()
            for (column, value) in zip(columns, record) where !value.isEmpty { values[column] = value }
            rows.append(Row(values: values))
        }
        return rows
    }

    struct Run {
        let scenario: String
        let sha: String
        let runIndex: Int
        let buildVariant: String
        /// Raw uptime nanoseconds by column name; a missing mark is absent.
        let marks: [String: UInt64]
        let decodeCount: Int?
        let flagSpecHasChanged: Bool?
        let filterHasChanged: Bool?
        let forceParsingRan: Bool?
        let cacheHit: Bool?
        let thermalBefore: String?
        let thermalAfter: String?
        let installState: String?
        /// Seconds since 1970 of `wallClockStart`.
        let wallClockSeconds: Double?

        /// T11 - T0 in milliseconds, when both are present and ordered.
        var totalMs: Double? {
            guard let start = marks["T0"], let end = marks["T11"], end >= start else { return nil }
            return BenchmarkAnalysis.milliseconds(from: start, to: end)
        }
    }

    static func milliseconds(from start: UInt64, to end: UInt64) -> Double {
        return Double(Int64(bitPattern: end &- start)) / 1_000_000
    }

    static func parseRuns(_ text: String) throws -> [Run] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        plain.timeZone = TimeZone(identifier: "UTC")

        func flag(_ value: String?) -> Bool? {
            switch value {
            case "true": return true
            case "false": return false
            default: return nil
            }
        }

        var runs = [Run]()
        for (offset, row) in try parse(text).enumerated() {
            guard let runIndex = row["runIndex"].flatMap({ Int($0) }) else {
                throw Failure.malformedRow(line: offset + 2)
            }
            var marks = [String: UInt64]()
            for column in markColumns {
                if let text = row[column], let nanos = UInt64(text) { marks[column] = nanos }
            }
            let wall = row["wallClockStart"].flatMap { formatter.date(from: $0) ?? plain.date(from: $0) }
            runs.append(Run(
                scenario: row["scenario"] ?? "", sha: row["sha"] ?? "", runIndex: runIndex,
                buildVariant: row["buildVariant"] ?? "", marks: marks,
                decodeCount: row["decodeCount"].flatMap { Int($0) },
                flagSpecHasChanged: flag(row["flagSpecHasChanged"]), filterHasChanged: flag(row["filterHasChanged"]),
                forceParsingRan: flag(row["forceParsingRan"]), cacheHit: flag(row["cacheHit"]),
                thermalBefore: row["thermalStateBefore"], thermalAfter: row["thermalStateAfter"],
                installState: row["installState"], wallClockSeconds: wall?.timeIntervalSince1970))
        }
        return runs
    }

    // MARK: 2. Statistics

    struct Stats: Equatable {
        let count: Int
        let median: Double
        let p90: Double
        let min: Double
        let max: Double
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count % 2 == 1 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
    }

    /// Nearest rank: sorted[ceil(0.9 n) - 1], with the ceiling taken in integers.
    static func p90(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let rank = (9 * values.count + 9) / 10
        return values.sorted()[rank - 1]
    }

    static func minimum(_ values: [Double]) -> Double? { return values.min() }

    static func maximum(_ values: [Double]) -> Double? { return values.max() }

    static func stats(_ values: [Double]) -> Stats? {
        guard let median = median(values), let p90 = p90(values), let low = minimum(values),
              let high = maximum(values) else { return nil }
        return Stats(count: values.count, median: median, p90: p90, min: low, max: high)
    }

    // MARK: 3. Paired block bootstrap

    /// SplitMix64: a tiny seeded generator, the only source of randomness in this file.
    struct SplitMix64 {
        private var state: UInt64

        init(seed: UInt64) { state = seed }

        mutating func next() -> UInt64 {
            state = state &+ 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        /// A value in 0..<bound (modulo bias is negligible for the small bounds used here).
        mutating func next(below bound: Int) -> Int {
            return Int(next() % UInt64(bound))
        }
    }

    struct Interval: Equatable {
        let point: Double
        let lower: Double
        let upper: Double

        var halfWidth: Double { return (upper - lower) / 2 }
    }

    /// 2.5th and 97.5th percentiles of ascending resample medians: indices floor(0.025 B) and ceil(0.975 B) - 1,
    /// computed in integers.
    static func percentileInterval(sortedResamples sorted: [Double]) -> (lower: Double, upper: Double)? {
        let count = sorted.count
        guard count > 0 else { return nil }
        let lowerIndex = min(max((25 * count) / 1000, 0), count - 1)
        let upperIndex = min(max((975 * count + 999) / 1000 - 1, 0), count - 1)
        return (sorted[lowerIndex], sorted[upperIndex])
    }

    /// Block bootstrap of the median of `values`: whole blocks are drawn with replacement and keep their members.
    static func blockBootstrap(values: [Double], blocks: [Int], resamples: Int, seed: UInt64) throws -> Interval? {
        guard values.count == blocks.count else {
            throw Failure.invalidInput("values and blocks differ in length")
        }
        guard resamples > 0 else { throw Failure.invalidInput("resamples must be positive") }
        guard let point = median(values) else { return nil }

        var order = [Int]()
        var members = [Int: [Double]]()
        for (value, block) in zip(values, blocks) {
            if members[block] == nil { order.append(block) }
            members[block, default: []].append(value)
        }
        let groups = order.map { members[$0]! }

        var generator = SplitMix64(seed: seed)
        var medians = [Double]()
        medians.reserveCapacity(resamples)
        var sample = [Double]()
        for _ in 0..<resamples {
            sample.removeAll(keepingCapacity: true)
            for _ in 0..<groups.count { sample.append(contentsOf: groups[generator.next(below: groups.count)]) }
            medians.append(median(sample)!)
        }
        medians.sort()
        guard let bounds = percentileInterval(sortedResamples: medians) else { return nil }
        return Interval(point: point, lower: bounds.lower, upper: bounds.upper)
    }

    /// 95% CI on the median of (candidate - baseline). Pairs stay together inside their block.
    static func pairedBlockBootstrap(baseline: [Double], candidate: [Double], blocks: [Int],
                                     resamples: Int = defaultResamples, seed: UInt64 = defaultSeed) throws -> Interval? {
        guard baseline.count == candidate.count else {
            throw Failure.invalidInput("baseline and candidate differ in length")
        }
        let deltas = zip(baseline, candidate).map { $1 - $0 }
        return try blockBootstrap(values: deltas, blocks: blocks, resamples: resamples, seed: seed)
    }

    /// 95% CI on the median of one series (used for the baseline's own noise).
    static func medianBootstrap(values: [Double], blocks: [Int], resamples: Int = defaultResamples,
                                seed: UInt64 = defaultSeed) throws -> Interval? {
        return try blockBootstrap(values: values, blocks: blocks, resamples: resamples, seed: seed)
    }

    // MARK: 4. One-sided bounds (spec 6.5)

    struct OneSidedBounds: Equatable {
        /// Upper CI bound of (candidate - baseline).
        let regressionUpper: Double
        /// Lower CI bound of (baseline - candidate).
        let improvementLower: Double
        let effectiveRegressionThreshold: Double
        let effectiveImprovementThreshold: Double
        let regressionPasses: Bool
        let improvementPasses: Bool
    }

    static func oneSidedBounds(baseline: [Double], candidate: [Double], blocks: [Int],
                               regressionThresholdMs: Double, improvementThresholdMs: Double,
                               msFloor: Double = defaultMsFloor, resamples: Int = defaultResamples,
                               seed: UInt64 = defaultSeed) throws -> OneSidedBounds? {
        guard let regression = try pairedBlockBootstrap(baseline: baseline, candidate: candidate, blocks: blocks,
                                                        resamples: resamples, seed: seed),
              // Improvement is measured on baseline - candidate, so the roles are swapped.
              let improvement = try pairedBlockBootstrap(baseline: candidate, candidate: baseline, blocks: blocks,
                                                         resamples: resamples, seed: seed) else { return nil }
        let effectiveRegression = max(regressionThresholdMs, msFloor)
        let effectiveImprovement = max(improvementThresholdMs, msFloor)
        return OneSidedBounds(
            regressionUpper: regression.upper, improvementLower: improvement.lower,
            effectiveRegressionThreshold: effectiveRegression, effectiveImprovementThreshold: effectiveImprovement,
            regressionPasses: regression.upper <= effectiveRegression,
            improvementPasses: improvement.lower >= effectiveImprovement)
    }

    // MARK: 5, 6. Minimum runs and baseline rejection

    static func hasMinimumRuns(_ count: Int, minRuns: Int = defaultMinRuns) -> Bool {
        return count >= minRuns
    }

    struct BaselineAssessment: Equatable {
        let halfWidthMs: Double
        /// Half-width as a percent of the baseline median; nil when the median is 0.
        let halfWidthPercent: Double?
        let rejected: Bool
        let reason: String?
    }

    /// Rejects a baseline whose CI half-width exceeds `maxHalfWidthPercent` of its median. The limit has no
    /// default: the caller (issue 33) fixes it.
    static func assessBaseline(interval: Interval, baselineMedian: Double,
                               maxHalfWidthPercent: Double) -> BaselineAssessment {
        let halfWidth = interval.halfWidth
        let percent: Double? = baselineMedian == 0 ? nil : halfWidth * 100 / abs(baselineMedian)
        let rejected = halfWidth * 100 > maxHalfWidthPercent * abs(baselineMedian)
        let reason = rejected
            ? "baseline too noisy: CI half-width \(halfWidth) ms exceeds \(maxHalfWidthPercent)% of the median "
                + "\(baselineMedian) ms; re-collect the baseline"
            : nil
        return BaselineAssessment(halfWidthMs: halfWidth, halfWidthPercent: percent, rejected: rejected, reason: reason)
    }

    struct Comparison {
        let pairCount: Int
        let insufficientRuns: Bool
        let baselineAssessment: BaselineAssessment?
        let bounds: OneSidedBounds?
    }

    /// Compares paired baseline and candidate totals. Fewer than `minRuns` pairs, or a rejected baseline, gives no
    /// verdict (`bounds` is nil).
    static func compare(baseline: [Double], candidate: [Double], blocks: [Int],
                        regressionThresholdMs: Double, improvementThresholdMs: Double,
                        maxHalfWidthPercent: Double, minRuns: Int = defaultMinRuns,
                        msFloor: Double = defaultMsFloor, resamples: Int = defaultResamples,
                        seed: UInt64 = defaultSeed) throws -> Comparison {
        guard baseline.count == candidate.count, baseline.count == blocks.count else {
            throw Failure.invalidInput("baseline, candidate and blocks differ in length")
        }
        let pairs = baseline.count
        guard hasMinimumRuns(pairs, minRuns: minRuns) else {
            return Comparison(pairCount: pairs, insufficientRuns: true, baselineAssessment: nil, bounds: nil)
        }
        guard let interval = try medianBootstrap(values: baseline, blocks: blocks, resamples: resamples, seed: seed),
              let baselineMedian = median(baseline) else {
            return Comparison(pairCount: pairs, insufficientRuns: true, baselineAssessment: nil, bounds: nil)
        }
        let assessment = assessBaseline(interval: interval, baselineMedian: baselineMedian,
                                        maxHalfWidthPercent: maxHalfWidthPercent)
        if assessment.rejected {
            return Comparison(pairCount: pairs, insufficientRuns: false, baselineAssessment: assessment, bounds: nil)
        }
        let bounds = try oneSidedBounds(
            baseline: baseline, candidate: candidate, blocks: blocks,
            regressionThresholdMs: regressionThresholdMs, improvementThresholdMs: improvementThresholdMs,
            msFloor: msFloor, resamples: resamples, seed: seed)
        return Comparison(pairCount: pairs, insufficientRuns: false, baselineAssessment: assessment, bounds: bounds)
    }

    // MARK: 7. Thermal

    struct ThermalExclusion: Equatable {
        let runIndex: Int
        let before: String?
        let after: String?
    }

    struct ThermalSplit {
        let nominal: [Run]
        let excluded: [ThermalExclusion]

        var excludedCount: Int { return excluded.count }
    }

    /// A run is nominal only when both thermal readings are exactly "nominal".
    static func isNominal(_ run: Run) -> Bool {
        return run.thermalBefore == "nominal" && run.thermalAfter == "nominal"
    }

    static func splitByThermal(_ runs: [Run]) -> ThermalSplit {
        var nominal = [Run]()
        var excluded = [ThermalExclusion]()
        for run in runs {
            if isNominal(run) {
                nominal.append(run)
            } else {
                excluded.append(ThermalExclusion(runIndex: run.runIndex, before: run.thermalBefore,
                                                 after: run.thermalAfter))
            }
        }
        return ThermalSplit(nominal: nominal, excluded: excluded)
    }

    // MARK: 8. Drift

    struct Drift: Equatable {
        let slopeMsPerHour: Double
        let count: Int
    }

    /// Least squares slope of the per-run total (ms) on the wall clock (seconds since the first run), in ms per hour.
    /// Needs at least two distinct start times.
    static func drift(runs: [Run]) -> Drift? {
        let points = runs.compactMap { run -> (x: Double, y: Double)? in
            guard let wall = run.wallClockSeconds, let total = run.totalMs else { return nil }
            return (wall, total)
        }
        guard let first = points.map({ $0.x }).min() else { return nil }
        let xs = points.map { $0.x - first }
        let ys = points.map { $0.y }
        let n = Double(points.count)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var sxx = 0.0
        var sxy = 0.0
        for (x, y) in zip(xs, ys) {
            sxx += (x - meanX) * (x - meanX)
            sxy += (x - meanX) * (y - meanY)
        }
        guard sxx > 0 else { return nil }
        return Drift(slopeMsPerHour: sxy / sxx * 3600, count: points.count)
    }

    // MARK: 9. Logging gap

    struct LoggingGap: Equatable {
        let scenario: String
        let sha: String
        let onMedianMs: Double?
        let offMedianMs: Double?
        /// median(logging-on) - median(logging-off); nil when either side is empty.
        let gapMs: Double?
    }

    static func loggingGap(scenario: String, sha: String, onTotals: [Double], offTotals: [Double]) -> LoggingGap {
        let on = median(onTotals)
        let off = median(offTotals)
        let gap: Double? = (on != nil && off != nil) ? on! - off! : nil
        return LoggingGap(scenario: scenario, sha: sha, onMedianMs: on, offMedianMs: off, gapMs: gap)
    }

    // MARK: 10, 11. R13 stage chains and shares

    enum Chain: String {
        case warm
        case cold
    }

    struct FailedRun: Equatable {
        let runIndex: Int
        let chain: Chain
        let missing: [String]
    }

    struct Stage: Equatable {
        let name: String
        let medianMs: Double
        /// Median as a fraction of the median total; nil when the median total is not positive.
        let share: Double?
        /// True when the median is under 1 ms (exactly 1 ms is resolved).
        let unresolved: Bool
    }

    struct ChainResult {
        let chain: Chain
        let runCount: Int
        let completeRunCount: Int
        let stages: [Stage]
        /// Union of the marks across all complete runs (not one chain's length): with mixed branches it can exceed
        /// any single run's chain. It sets the per-mark arm of the R13 tolerance.
        let markCount: Int
        let medianTotalMs: Double?
        let sumOfStageMedians: Double
        let toleranceMs: Double
        let passes: Bool
    }

    struct R13Result {
        let warm: ChainResult?
        let cold: ChainResult?
        let failedRuns: [FailedRun]
        let passes: Bool
    }

    private static let warmRequired = ["T0", "T1", "T2", "T3", "T5", "T7", "T8", "T10", "T11"]
    private static let coldEndMarks = ["coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated",
                                       "coldEnd_myLargeSegmentsUpdated"]
    private static let coldRequired = ["T0", "T1", "T2", "T3", "T5"] + coldEndMarks + ["T11"]

    /// A cache miss run, or any scenario D run, is judged on the cold chain.
    static func usesColdChain(_ run: Run) -> Bool {
        return run.cacheHit == false || run.scenario == "D"
    }

    static func r13Tolerance(medianTotalMs: Double, markCount: Int) -> Double {
        return max(medianTotalMs / 10, Double(markCount))
    }

    /// The ordered marks of a run's chain; the run must have every required mark.
    private static func chainMarks(of run: Run, chain: Chain) -> [String] {
        let marks = run.marks
        switch chain {
        case .warm:
            let branch = marks["T8"]! >= marks["T10"]! ? ["T5", "T7", "T8"] : ["T10"]
            return ["T0", "T1", "T2", "T3"] + branch + ["T11"]
        case .cold:
            let ordered = coldEndMarks.enumerated().sorted {
                (marks[$0.element]!, $0.offset) < (marks[$1.element]!, $1.offset)
            }.map { $0.element }
            return ["T0", "T1", "T2", "T3", "T5"] + ordered + ["T11"]
        }
    }

    static func checkR13(runs: [Run]) -> R13Result {
        var failed = [FailedRun]()
        var warmRuns = 0
        var coldRuns = 0
        var warmComplete = [(run: Run, marks: [String])]()
        var coldComplete = [(run: Run, marks: [String])]()

        for run in runs {
            let chain: Chain = usesColdChain(run) ? .cold : .warm
            let required = chain == .cold ? coldRequired : warmRequired
            if chain == .cold { coldRuns += 1 } else { warmRuns += 1 }
            let missing = required.filter { run.marks[$0] == nil }
            if !missing.isEmpty {
                failed.append(FailedRun(runIndex: run.runIndex, chain: chain, missing: missing))
                continue
            }
            let entry = (run: run, marks: chainMarks(of: run, chain: chain))
            if chain == .cold { coldComplete.append(entry) } else { warmComplete.append(entry) }
        }

        let warm = warmRuns > 0 ? chainResult(.warm, runCount: warmRuns, complete: warmComplete) : nil
        let cold = coldRuns > 0 ? chainResult(.cold, runCount: coldRuns, complete: coldComplete) : nil
        let chainsPass = [warm, cold].compactMap { $0 }.allSatisfy { $0.passes }
        let anyChain = warm != nil || cold != nil
        return R13Result(warm: warm, cold: cold, failedRuns: failed, passes: anyChain && chainsPass && failed.isEmpty)
    }

    private static func chainResult(_ chain: Chain, runCount: Int,
                                    complete: [(run: Run, marks: [String])]) -> ChainResult {
        var names = [String]()
        var deltas = [String: [Double]]()
        var distinctMarks = Set<String>()
        var totals = [Double]()
        for (run, marks) in complete {
            distinctMarks.formUnion(marks)
            for (from, to) in zip(marks, marks.dropFirst()) {
                let name = "\(from)->\(to)"
                if deltas[name] == nil { names.append(name) }
                deltas[name, default: []].append(milliseconds(from: run.marks[from]!, to: run.marks[to]!))
            }
            totals.append(milliseconds(from: run.marks["T0"]!, to: run.marks["T11"]!))
        }
        let medianTotal = median(totals)
        let medians = names.map { median(deltas[$0]!)! }
        let sum = medians.reduce(0, +)
        let stages = zip(names, medians).map { name, value -> Stage in
            let share: Double? = (medianTotal ?? 0) > 0 ? value / medianTotal! : nil
            return Stage(name: name, medianMs: value, share: share, unresolved: value < 1)
        }
        let tolerance = medianTotal.map { r13Tolerance(medianTotalMs: $0, markCount: distinctMarks.count) } ?? 0
        let passes = medianTotal != nil && abs(sum - medianTotal!) <= tolerance
        return ChainResult(chain: chain, runCount: runCount, completeRunCount: complete.count, stages: stages,
                           markCount: distinctMarks.count, medianTotalMs: medianTotal, sumOfStageMedians: sum,
                           toleranceMs: tolerance, passes: passes)
    }

    // MARK: 12. R18 decode share

    private static let decodeSites: [(start: String, end: String)] = [
        ("T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end"),
        ("T6_forceParsing_start", "T6_forceParsing_end"),
        ("T6_loadLocal_start", "T6_loadLocal_end")
    ]

    /// Sum of (end - start) over the call sites that have both marks, divided by T11 - T0. Nil without a total.
    static func decodeShare(_ run: Run) -> Double? {
        guard let total = run.totalMs, total > 0 else { return nil }
        var decode = 0.0
        for site in decodeSites {
            if let start = run.marks[site.start], let end = run.marks[site.end] {
                decode += milliseconds(from: start, to: end)
            }
        }
        return decode / total
    }

    static func decodeShareMedian(runs: [Run]) -> Double? {
        return median(runs.compactMap { decodeShare($0) })
    }

    // MARK: 13. R19 run classes

    enum RunClass: String, CaseIterable {
        case warmCacheHit
        case flagSpecOrFilterChange
        case firstRunForceParsing
        case cacheMiss
        case moreThanOneDecode
        case unknown
    }

    /// The first matching class in the fixed R19 order. A run matching none is `unknown`, never dropped.
    static func runClass(_ run: Run) -> RunClass {
        if run.cacheHit == true && run.flagSpecHasChanged != true && run.filterHasChanged != true
            && run.forceParsingRan != true && (run.decodeCount.map { $0 <= 1 } ?? false) {
            return .warmCacheHit
        }
        if run.flagSpecHasChanged == true || run.filterHasChanged == true { return .flagSpecOrFilterChange }
        if run.forceParsingRan == true { return .firstRunForceParsing }
        if run.cacheHit == false { return .cacheMiss }
        if (run.decodeCount.map { $0 > 1 } ?? false) { return .moreThanOneDecode }
        return .unknown
    }

    static func isFirstInstall(_ run: Run) -> Bool {
        return run.installState == "first"
    }
}

// MARK: 14. Report

/// The analysis of one (scenario, buildVariant, sha) group.
struct BenchmarkAnalysisReport {

    struct Entry: Equatable {
        let runIndex: Int
        let runClass: BenchmarkAnalysis.RunClass
        let firstInstall: Bool
        let thermalNominal: Bool
        let thermalBefore: String?
        let thermalAfter: String?
        let isPrimary: Bool
        /// Why the run is not primary: "class:<label>", "thermal:<before>/<after>", "firstInstall", "noTotal".
        let reasons: [String]
    }

    let scenario: String
    let buildVariant: String
    let sha: String
    let totalRuns: Int
    let primaryCount: Int
    let thermalExclusions: [BenchmarkAnalysis.ThermalExclusion]
    let entries: [Entry]
    let insufficientRuns: Bool
    let primaryTotalsMs: [Double]
    let stats: BenchmarkAnalysis.Stats?
    let r13: BenchmarkAnalysis.R13Result
    let decodeShareMedian: Double?
    let drift: BenchmarkAnalysis.Drift?

    var thermalExcludedCount: Int { return thermalExclusions.count }
    var nonPrimary: [Entry] { return entries.filter { !$0.isPrimary } }

    /// One report per group, ordered by scenario, build variant and sha. Primary runs are warm cache hits with
    /// nominal thermal state that are not first installs and have a total. Stage chains (R13) look at every run.
    static func build(runs: [BenchmarkAnalysis.Run],
                      minRuns: Int = BenchmarkAnalysis.defaultMinRuns) -> [BenchmarkAnalysisReport] {
        var order = [String]()
        var groups = [String: [BenchmarkAnalysis.Run]]()
        for run in runs {
            let key = [run.scenario, run.buildVariant, run.sha].joined(separator: "\u{1F}")
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(run)
        }
        return order.sorted().map { report(for: groups[$0]!, minRuns: minRuns) }
    }

    private static func report(for runs: [BenchmarkAnalysis.Run], minRuns: Int) -> BenchmarkAnalysisReport {
        var entries = [Entry]()
        var primary = [BenchmarkAnalysis.Run]()
        for run in runs {
            let runClass = BenchmarkAnalysis.runClass(run)
            let nominal = BenchmarkAnalysis.isNominal(run)
            let firstInstall = BenchmarkAnalysis.isFirstInstall(run)
            var reasons = [String]()
            if runClass != .warmCacheHit { reasons.append("class:\(runClass.rawValue)") }
            if !nominal { reasons.append("thermal:\(run.thermalBefore ?? "missing")/\(run.thermalAfter ?? "missing")") }
            if firstInstall { reasons.append("firstInstall") }
            if reasons.isEmpty && run.totalMs == nil { reasons.append("noTotal") }
            if reasons.isEmpty { primary.append(run) }
            entries.append(Entry(runIndex: run.runIndex, runClass: runClass, firstInstall: firstInstall,
                                 thermalNominal: nominal, thermalBefore: run.thermalBefore,
                                 thermalAfter: run.thermalAfter, isPrimary: reasons.isEmpty, reasons: reasons))
        }
        let totals = primary.compactMap { $0.totalMs }
        return BenchmarkAnalysisReport(
            scenario: runs[0].scenario, buildVariant: runs[0].buildVariant, sha: runs[0].sha,
            totalRuns: runs.count, primaryCount: primary.count,
            thermalExclusions: BenchmarkAnalysis.splitByThermal(runs).excluded, entries: entries,
            insufficientRuns: !BenchmarkAnalysis.hasMinimumRuns(primary.count, minRuns: minRuns),
            primaryTotalsMs: totals, stats: BenchmarkAnalysis.stats(totals),
            r13: BenchmarkAnalysis.checkR13(runs: runs),
            decodeShareMedian: BenchmarkAnalysis.decodeShareMedian(runs: primary),
            drift: BenchmarkAnalysis.drift(runs: primary))
    }

    /// Logging gap per (scenario, sha), from the primary totals of the logging-on and logging-off groups.
    static func loggingGaps(_ reports: [BenchmarkAnalysisReport]) -> [BenchmarkAnalysis.LoggingGap] {
        var keys = [String: (scenario: String, sha: String)]()
        for report in reports {
            keys[report.scenario + "\u{1F}" + report.sha] = (report.scenario, report.sha)
        }
        return keys.keys.sorted().map { key in
            let (scenario, sha) = keys[key]!
            func totals(_ variant: String) -> [Double] {
                return reports.filter { $0.scenario == scenario && $0.sha == sha && $0.buildVariant == variant }
                    .flatMap { $0.primaryTotalsMs }
            }
            return BenchmarkAnalysis.loggingGap(scenario: scenario, sha: sha, onTotals: totals("logging-on"),
                                                offTotals: totals("logging-off"))
        }
    }

    /// A human readable report: a header per group followed by the run class of every run.
    func summary() -> String {
        var lines = ["\(scenario) / \(buildVariant) / \(sha): runs=\(totalRuns) primary=\(primaryCount) "
                     + "thermalExcluded=\(thermalExcludedCount)" + (insufficientRuns ? " insufficientRuns" : "")]
        if let stats = stats {
            lines.append("  totals ms: median=\(stats.median) p90=\(stats.p90) min=\(stats.min) max=\(stats.max)")
        }
        lines.append("  R13: " + (r13.passes ? "pass" : "FAIL") + ", failed runs=\(r13.failedRuns.map { $0.runIndex })")
        for entry in entries {
            var line = "  run \(entry.runIndex): \(entry.runClass.rawValue)"
            if entry.firstInstall { line += " firstInstall" }
            if !entry.thermalNominal {
                line += " thermal:\(entry.thermalBefore ?? "missing")/\(entry.thermalAfter ?? "missing")"
            }
            if !entry.isPrimary { line += " (non-primary)" }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    static func summary(_ reports: [BenchmarkAnalysisReport]) -> String {
        var sections = reports.map { $0.summary() }
        for gap in loggingGaps(reports) {
            let value = gap.gapMs.map { String($0) } ?? "n/a"
            sections.append("logging gap \(gap.scenario) / \(gap.sha): \(value) ms "
                            + "(on=\(gap.onMedianMs.map { String($0) } ?? "n/a"), "
                            + "off=\(gap.offMedianMs.map { String($0) } ?? "n/a"))")
        }
        return sections.joined(separator: "\n")
    }
}

//
//  BenchmarkCSVRowTest.swift
//  SplitBenchmark
//

import XCTest
@testable import Split

class BenchmarkCSVRowTest: XCTestCase {

    private let allMarks: [(name: String, nanos: UInt64)] = [
        ("T1 storage container built", 101), ("T2 cache validated", 102),
        ("T3 SyncManager loadData entered", 103), ("T5 splits load started", 105),
        ("T6 decode start [filterSplitsInCache]", 1061), ("T6 decode end [filterSplitsInCache]", 1062),
        ("T6 decode start [forceParsing]", 1063), ("T6 decode end [forceParsing]", 1064),
        ("T6 decode start [loadLocal]", 1065), ("T6 decode end [loadLocal]", 1066),
        ("T7 processUpdated done", 107), ("T8 splitsLoadedFromCache notified", 108),
        ("T10 large segments loaded", 110),
        ("ColdEnd splitsUpdated notified", 201), ("ColdEnd mySegmentsUpdated notified", 202),
        ("ColdEnd myLargeSegmentsUpdated notified", 203),
        ("RunClass flagSpecHasChanged=true filterHasChanged=false", 150)
    ]

    private func arguments(_ extra: [String] = []) throws -> BenchmarkArguments {
        return try BenchmarkArguments.parse(["-benchScenario", "B", "-benchSHA", "deadbeef", "-benchRunIndex", "4",
                                             "-benchWidth", "2", "-benchIdleGapSeconds", "30"] + extra)
    }

    private func row(marks: [(name: String, nanos: UInt64)], extra: [String] = []) throws -> BenchmarkCSVRow {
        return BenchmarkCSVRow(arguments: try arguments(extra), fixtureSeed: 22007, fixtureHash: "abc123",
                               t0: 100, t11: 300, marks: marks, thermalBefore: .nominal, thermalAfter: .fair,
                               wallClockStart: Date(timeIntervalSince1970: 0))
    }

    private func dictionary(_ row: BenchmarkCSVRow) -> [String: String] {
        return Dictionary(uniqueKeysWithValues: zip(BenchmarkCSVRow.columns, row.fields))
    }

    private let issue27Columns = [
        "scenario", "sha", "runIndex", "buildVariant", "width", "fixtureSeed", "fixtureHash",
        "T0", "T1", "T2", "T3", "T5",
        "T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end",
        "T6_forceParsing_start", "T6_forceParsing_end",
        "T6_loadLocal_start", "T6_loadLocal_end", "T6Count",
        "T7", "T8", "T10",
        "coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated", "coldEnd_myLargeSegmentsUpdated",
        "T11", "flagSpecHasChanged", "filterHasChanged", "forceParsingRan", "cacheHit", "decodeCount",
        "thermalStateBefore", "thermalStateAfter", "idleGapSeconds", "installState", "wallClockStart",
        "readyAPI"]

    func test_issue27Columns_keepOrderAsPrefix_runnerColumnsAppended() {
        XCTAssertEqual(Array(BenchmarkCSVRow.columns.prefix(issue27Columns.count)), issue27Columns)
        XCTAssertEqual(Array(BenchmarkCSVRow.columns.dropFirst(issue27Columns.count)),
                       ["factoryIndex", "apiKeyIdentity", "bothReadyNs", "t8ToFireNs", "deletedBeforeMeasure",
                        "populatedThisRun", "payloadMultiplier"])
    }

    func test_extras_landInTheirOwnColumns_andDefaultToEmpty() throws {
        let extras = BenchmarkRowExtras(factoryIndex: "2", apiKeyIdentity: "keyB", bothReadyNs: "99", t8ToFireNs: "7",
                                        deletedBeforeMeasure: "true", populatedThisRun: "false",
                                        payloadMultiplier: "4")
        let full = BenchmarkCSVRow(arguments: try arguments(), fixtureSeed: 1, fixtureHash: "h", t0: 1, t11: 2,
                                   marks: [], thermalBefore: .nominal, thermalAfter: .nominal,
                                   wallClockStart: Date(timeIntervalSince1970: 0), extras: extras)
        let plain = try row(marks: [])

        let values = dictionary(full)
        XCTAssertEqual(values["factoryIndex"], "2")
        XCTAssertEqual(values["apiKeyIdentity"], "keyB")
        XCTAssertEqual(values["bothReadyNs"], "99")
        XCTAssertEqual(values["t8ToFireNs"], "7")
        XCTAssertEqual(values["deletedBeforeMeasure"], "true")
        XCTAssertEqual(values["populatedThisRun"], "false")
        XCTAssertEqual(values["payloadMultiplier"], "4")
        XCTAssertEqual(plain.fields.count, BenchmarkCSVRow.columns.count)
        XCTAssertEqual(Array(plain.fields.suffix(7)), Array(repeating: "", count: 7))
    }

    func test_columnOrder_isFixed() {
        XCTAssertEqual(Array(BenchmarkCSVRow.columns.prefix(issue27Columns.count)), [
            "scenario", "sha", "runIndex", "buildVariant", "width", "fixtureSeed", "fixtureHash",
            "T0", "T1", "T2", "T3", "T5",
            "T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end",
            "T6_forceParsing_start", "T6_forceParsing_end",
            "T6_loadLocal_start", "T6_loadLocal_end", "T6Count",
            "T7", "T8", "T10",
            "coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated", "coldEnd_myLargeSegmentsUpdated",
            "T11", "flagSpecHasChanged", "filterHasChanged", "forceParsingRan", "cacheHit", "decodeCount",
            "thermalStateBefore", "thermalStateAfter", "idleGapSeconds", "installState", "wallClockStart",
            "readyAPI"])
        XCTAssertEqual(Set(BenchmarkCSVRow.columns).count, BenchmarkCSVRow.columns.count, "duplicate column")
    }

    func test_header_isColumnsJoinedWithNewline() {
        XCTAssertEqual(BenchmarkCSVRow.header(), BenchmarkCSVRow.columns.joined(separator: ",") + "\n")
    }

    func test_fullRow_everyColumnFromItsSource() throws {
        let values = dictionary(try row(marks: allMarks, extra: ["-benchLogging", "off", "-benchReadyAPI", "listener",
                                                                 "-benchInstallState", "first"]))

        XCTAssertEqual(values["scenario"], "B")
        XCTAssertEqual(values["sha"], "deadbeef")
        XCTAssertEqual(values["runIndex"], "4")
        XCTAssertEqual(values["buildVariant"], "logging-off")
        XCTAssertEqual(values["width"], "2")
        XCTAssertEqual(values["fixtureSeed"], "22007")
        XCTAssertEqual(values["fixtureHash"], "abc123")
        XCTAssertEqual(values["T0"], "100")
        XCTAssertEqual(values["T1"], "101")
        XCTAssertEqual(values["T2"], "102")
        XCTAssertEqual(values["T3"], "103")
        XCTAssertEqual(values["T5"], "105")
        XCTAssertEqual(values["T6_filterSplitsInCache_start"], "1061")
        XCTAssertEqual(values["T6_filterSplitsInCache_end"], "1062")
        XCTAssertEqual(values["T6_forceParsing_start"], "1063")
        XCTAssertEqual(values["T6_forceParsing_end"], "1064")
        XCTAssertEqual(values["T6_loadLocal_start"], "1065")
        XCTAssertEqual(values["T6_loadLocal_end"], "1066")
        XCTAssertEqual(values["T6Count"], "3")
        XCTAssertEqual(values["T7"], "107")
        XCTAssertEqual(values["T8"], "108")
        XCTAssertEqual(values["T10"], "110")
        XCTAssertEqual(values["coldEnd_splitsUpdated"], "201")
        XCTAssertEqual(values["coldEnd_mySegmentsUpdated"], "202")
        XCTAssertEqual(values["coldEnd_myLargeSegmentsUpdated"], "203")
        XCTAssertEqual(values["T11"], "300")
        XCTAssertEqual(values["flagSpecHasChanged"], "true")
        XCTAssertEqual(values["filterHasChanged"], "false")
        XCTAssertEqual(values["forceParsingRan"], "true")
        XCTAssertEqual(values["cacheHit"], "true")
        XCTAssertEqual(values["decodeCount"], "3")
        XCTAssertEqual(values["thermalStateBefore"], "nominal")
        XCTAssertEqual(values["thermalStateAfter"], "fair")
        XCTAssertEqual(values["idleGapSeconds"], "30.0")
        XCTAssertEqual(values["installState"], "first")
        XCTAssertEqual(values["wallClockStart"], "1970-01-01T00:00:00.000Z")
        XCTAssertEqual(values["readyAPI"], "listener")
    }

    func test_missingMarks_areEmptyFields_andRowKeepsEveryColumn() throws {
        let marks = [allMarks[0], allMarks[2]]   // only T1 and T3
        let built = try row(marks: marks)
        let values = dictionary(built)

        XCTAssertEqual(built.fields.count, BenchmarkCSVRow.columns.count)
        XCTAssertEqual(values["T1"], "101")
        XCTAssertEqual(values["T3"], "103")
        for empty in ["T2", "T5", "T6_filterSplitsInCache_start", "T6_filterSplitsInCache_end",
                      "T6_forceParsing_start", "T6_forceParsing_end", "T6_loadLocal_start", "T6_loadLocal_end",
                      "T7", "T8", "T10", "coldEnd_splitsUpdated", "coldEnd_mySegmentsUpdated",
                      "coldEnd_myLargeSegmentsUpdated", "flagSpecHasChanged", "filterHasChanged"] {
            XCTAssertEqual(values[empty], "", empty)
        }
        XCTAssertEqual(values["T6Count"], "0")
        XCTAssertEqual(values["decodeCount"], "0")
        XCTAssertEqual(values["cacheHit"], "false")
        XCTAssertEqual(values["forceParsingRan"], "false")
        XCTAssertEqual(built.line().split(separator: ",", omittingEmptySubsequences: false).count,
                       BenchmarkCSVRow.columns.count)
    }

    func test_cacheHit_followsT8_forceParsing_followsItsDecodeStart() throws {
        let withT8Only = dictionary(try row(marks: [allMarks[11]]))
        XCTAssertEqual(withT8Only["cacheHit"], "true")
        XCTAssertEqual(withT8Only["forceParsingRan"], "false")

        let forceOnly = dictionary(try row(marks: [allMarks[6]]))
        XCTAssertEqual(forceOnly["cacheHit"], "false")
        XCTAssertEqual(forceOnly["forceParsingRan"], "true")
        XCTAssertEqual(forceOnly["T6Count"], "1")
    }

    func test_runClass_parsedFromMarkName() throws {
        let marks: [(name: String, nanos: UInt64)] = [("RunClass flagSpecHasChanged=false filterHasChanged=true", 9)]
        let values = dictionary(try row(marks: marks))
        XCTAssertEqual(values["flagSpecHasChanged"], "false")
        XCTAssertEqual(values["filterHasChanged"], "true")
    }

    func test_firstOccurrenceOfDuplicateMark_wins() throws {
        let marks: [(name: String, nanos: UInt64)] = [("T7 processUpdated done", 5), ("T7 processUpdated done", 9)]
        XCTAssertEqual(dictionary(try row(marks: marks))["T7"], "5")
    }

    func test_widthEmpty_whenNoOverride() throws {
        let noWidth = BenchmarkCSVRow(arguments: try BenchmarkArguments.parse(["-benchScenario", "A"]),
                                      fixtureSeed: 1, fixtureHash: "h", t0: 1, t11: 2, marks: [],
                                      thermalBefore: .nominal, thermalAfter: .nominal, wallClockStart: Date())
        XCTAssertEqual(dictionary(noWidth)["width"], "")
    }

    func test_thermalNames() {
        XCTAssertEqual(BenchmarkCSVRow.thermalName(.nominal), "nominal")
        XCTAssertEqual(BenchmarkCSVRow.thermalName(.fair), "fair")
        XCTAssertEqual(BenchmarkCSVRow.thermalName(.serious), "serious")
        XCTAssertEqual(BenchmarkCSVRow.thermalName(.critical), "critical")
    }

    func test_escape_rfc4180() {
        XCTAssertEqual(BenchmarkCSVRow.escape("plain"), "plain")
        XCTAssertEqual(BenchmarkCSVRow.escape("a,b"), "\"a,b\"")
        XCTAssertEqual(BenchmarkCSVRow.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
        XCTAssertEqual(BenchmarkCSVRow.escape("line1\nline2"), "\"line1\nline2\"")
    }

    func test_line_escapesFieldsAndEndsWithNewline() throws {
        let args = try BenchmarkArguments.parse(["-benchScenario", "A", "-benchSHA", "a,b"])
        let built = BenchmarkCSVRow(arguments: args, fixtureSeed: 1, fixtureHash: "h", t0: 1, t11: 2, marks: [],
                                    thermalBefore: .nominal, thermalAfter: .nominal, wallClockStart: Date())
        XCTAssertTrue(built.line().hasPrefix("A,\"a,b\",0,"))
        XCTAssertTrue(built.line().hasSuffix("\n"))
        XCTAssertFalse(built.line().contains("\r"))
    }

    func test_writer_headerOnceThenOneRowPerRun() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bench_\(UUID().uuidString).csv")
        defer { try? FileManager.default.removeItem(at: url) }

        try row(marks: allMarks).append(to: url)
        try row(marks: []).append(to: url)

        let lines = try String(contentsOf: url).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4, "header, two rows, trailing empty")
        XCTAssertEqual(lines[0] + "\n", BenchmarkCSVRow.header())
        XCTAssertEqual(lines[1].components(separatedBy: ",").count, BenchmarkCSVRow.columns.count)
        XCTAssertEqual(lines[2].components(separatedBy: ",").count, BenchmarkCSVRow.columns.count)
        XCTAssertEqual(lines[3], "")
    }
}

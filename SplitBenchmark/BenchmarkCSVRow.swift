//
//  BenchmarkCSVRow.swift
//  SplitBenchmark
//
//  FME-22007: one CSV row per benchmark run, fixed column order.
//
//  Marks are written as raw monotonic uptime nanoseconds, exactly as recorded; deltas are computed later.
//  A missing mark is an empty field, never a dropped one.
//  forceParsingRan is true when the "T6 decode start [forceParsing]" mark is present. The "Force Parsing
//  flags" log line is not recorded by the stage-mark recorder, so it cannot be used.
//

import Foundation

struct BenchmarkCSVRow: Equatable {

    typealias Mark = (name: String, nanos: UInt64)

    static let columns = [
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

    /// Field values in `columns` order.
    let fields: [String]

    private static let markColumns: [(column: String, mark: String)] = [
        ("T1", "T1 storage container built"),
        ("T2", "T2 cache validated"),
        ("T3", "T3 SyncManager loadData entered"),
        ("T5", "T5 splits load started"),
        ("T6_filterSplitsInCache_start", "T6 decode start [filterSplitsInCache]"),
        ("T6_filterSplitsInCache_end", "T6 decode end [filterSplitsInCache]"),
        ("T6_forceParsing_start", "T6 decode start [forceParsing]"),
        ("T6_forceParsing_end", "T6 decode end [forceParsing]"),
        ("T6_loadLocal_start", "T6 decode start [loadLocal]"),
        ("T6_loadLocal_end", "T6 decode end [loadLocal]"),
        ("T7", "T7 processUpdated done"),
        ("T8", "T8 splitsLoadedFromCache notified"),
        ("T10", "T10 large segments loaded"),
        ("coldEnd_splitsUpdated", "ColdEnd splitsUpdated notified"),
        ("coldEnd_mySegmentsUpdated", "ColdEnd mySegmentsUpdated notified"),
        ("coldEnd_myLargeSegmentsUpdated", "ColdEnd myLargeSegmentsUpdated notified")
    ]

    private static let runClassPrefix = "RunClass "
    private static let t6StartPrefix = "T6 decode start ["

    init(arguments: BenchmarkArguments, fixtureSeed: UInt64, fixtureHash: String, t0: UInt64, t11: UInt64,
         marks: [Mark], thermalBefore: ProcessInfo.ThermalState, thermalAfter: ProcessInfo.ThermalState,
         wallClockStart: Date) {
        var values = [String: String]()
        values["scenario"] = arguments.scenario.rawValue
        values["sha"] = arguments.sha
        values["runIndex"] = String(arguments.runIndex)
        values["buildVariant"] = arguments.buildVariant
        values["width"] = arguments.width.map { String($0) } ?? ""
        values["fixtureSeed"] = String(fixtureSeed)
        values["fixtureHash"] = fixtureHash
        values["T0"] = String(t0)
        values["T11"] = String(t11)

        for entry in Self.markColumns {
            values[entry.column] = marks.first { $0.name == entry.mark }.map { String($0.nanos) } ?? ""
        }
        let t6Count = marks.filter { $0.name.hasPrefix(Self.t6StartPrefix) }.count
        values["T6Count"] = String(t6Count)
        values["decodeCount"] = String(t6Count)
        values["forceParsingRan"] = Self.flag(marks.contains { $0.name == "T6 decode start [forceParsing]" })
        values["cacheHit"] = Self.flag(marks.contains { $0.name == "T8 splitsLoadedFromCache notified" })

        let runClass = marks.first { $0.name.hasPrefix(Self.runClassPrefix) }?.name ?? ""
        values["flagSpecHasChanged"] = Self.booleanValue(after: "flagSpecHasChanged=", in: runClass)
        values["filterHasChanged"] = Self.booleanValue(after: "filterHasChanged=", in: runClass)

        values["thermalStateBefore"] = Self.thermalName(thermalBefore)
        values["thermalStateAfter"] = Self.thermalName(thermalAfter)
        values["idleGapSeconds"] = String(arguments.idleGapSeconds)
        values["installState"] = arguments.installState.rawValue
        values["wallClockStart"] = Self.iso8601(wallClockStart)
        values["readyAPI"] = arguments.readyAPI.rawValue

        fields = Self.columns.map { values[$0] ?? "" }
    }

    static func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    static func header() -> String {
        return columns.joined(separator: ",") + "\n"
    }

    /// The row line, RFC 4180 escaped, terminated by `\n`.
    func line() -> String {
        return fields.map(Self.escape).joined(separator: ",") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Appends one row to the file, writing the header first when the file is new.
    func append(to url: URL) throws {
        let manager = FileManager.default
        var text = ""
        if !manager.fileExists(atPath: url.path) {
            text = Self.header()
            guard manager.createFile(atPath: url.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        text += line()
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        handle.seekToEndOfFile()
        handle.write(Data(text.utf8))
    }

    private static func flag(_ value: Bool) -> String { value ? "true" : "false" }

    private static func booleanValue(after key: String, in text: String) -> String {
        guard let range = text.range(of: key) else { return "" }
        let rest = text[range.upperBound...]
        if rest.hasPrefix("true") { return "true" }
        if rest.hasPrefix("false") { return "false" }
        return ""
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}

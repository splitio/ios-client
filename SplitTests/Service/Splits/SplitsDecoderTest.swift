//
//  SplitsDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitsDecoderTest: XCTestCase {

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

    func testDecodeOneThread() throws {

        let decoder = SplitsParallelDecoder(minTaskPerThread: 15, timeChecker: TimeChecker.forTesting())
        let jsons = Array(loadJsonSplits()[..<10])

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    func testDecodeTwoThreads() throws {

        let decoder = SplitsParallelDecoder(minTaskPerThread: 15, timeChecker: TimeChecker.forTesting())
        let jsons = Array(loadJsonSplits()[0..<30])

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    func testDecodeMultiThreads() throws {

        let decoder = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting())
        let jsons = loadJsonSplits(times: 10)

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    // MARK: - Characterisation against the decoder output at b7f5995d
    // Golden files were dumped from the unmodified production decoder at b7f5995d.
    // Decoded changeNumber is nil at that commit (getSplit does not set it); the golden records that as-is.

    func test_golden_parallelDecode_matchesHeadSortedList_100Flags() throws {
        let flags = try loadFlags(100)
        XCTAssertEqual(flags.count, 100)

        let splits = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting())
            .decode(flags)

        XCTAssertEqual(splits.count, 100)
        XCTAssertGreaterThan(taskCountLogs().first ?? 0, 1)
        let actual = splits.map(entry).sorted { ($0.name ?? "") < ($1.name ?? "") }
        XCTAssertEqual(actual, try loadGolden(100))
    }

    func test_boundary_10Flags_serialPath_preservesListOrder() throws {
        let flags = try loadFlags(10)
        XCTAssertEqual(flags.count, 10)

        let splits = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting())
            .decode(flags)

        XCTAssertEqual(taskCountLogs(), [1])
        let actual = splits.map(entry)
        XCTAssertEqual(actual.compactMap { $0.name },
                       ["flag_001", "flag_002", "flag_003", "flag_004", "flag_005",
                        "flag_006", "flag_007", "flag_008", "flag_009", "flag_010"])
        XCTAssertEqual(actual, try loadGolden(10))
    }

    func test_boundary_11Flags_parallelPath_taskCountGreaterThanOne() throws {
        let flags = try loadFlags(11)
        XCTAssertEqual(flags.count, 11)

        let splits = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting())
            .decode(flags)

        XCTAssertEqual(splits.count, 11)
        XCTAssertGreaterThan(taskCountLogs().first ?? 0, 1)
        let actual = splits.map(entry).sorted { ($0.name ?? "") < ($1.name ?? "") }
        XCTAssertEqual(actual, try loadGolden(11))
    }

    func test_corruptPayload_skippedAsAtHead() throws {
        let input = corruptPayloadInput()
        XCTAssertGreaterThanOrEqual(input.count, 12)

        printerStub.clear()
        let parallel = SplitsParallelDecoder(minTaskPerThread: 10, timeChecker: TimeChecker.forTesting())
            .decode(input)
        let parallelNames = parallel.compactMap { $0.name }.sorted()
        let parallelLogs = printerStub.logsSnapshot()
        XCTAssertEqual(parallelNames, ["ok_1", "ok_2", "ok_3", "ok_4", "ok_5", "ok_6"])
        XCTAssertEqual(parallelLogs.filter { $0.contains("Failed decoding feature flag json") }.count, 6)
        XCTAssertEqual(parallelLogs.filter { $0.contains("Error decoding split") }.count, 5)

        printerStub.clear()
        let serial = SplitsSerialDecoder(cipher: nil).decode(input)
        let serialNames = serial.compactMap { $0.name }.sorted()
        let serialLogs = printerStub.logsSnapshot()
        XCTAssertEqual(serialNames, ["ok_1", "ok_2", "ok_3", "ok_4", "ok_5", "ok_6"])
        XCTAssertEqual(serialLogs.filter { $0.contains("Failed decoding feature flag json") }.count, 6)
        XCTAssertEqual(serialLogs.filter { $0.contains("Error decoding split") }.count, 5)
    }

    func test_processCount_scaleDown_matchesFormula() throws {
        let cores = ProcessInfo.processInfo.processorCount
        try XCTSkipIf(cores < 3, "needs at least 3 cores so the (11,10) scale-down differs from core count")

        let pairs: [(total: Int, min: Int)] = [(11, 10), (15, 10), (25, 10), (15, 5)]
        for pair in pairs {
            XCTAssertGreaterThan(pair.total, pair.min)
            let actual = ThreadUtils.processCount(totalTaskCount: pair.total, minTaskPerThread: pair.min)
            if pair.min * cores > pair.total {
                // Scale-down branch: cores - ((min*cores - total) / min)
                let expected = cores - ((pair.min * cores - pair.total) / pair.min)
                XCTAssertEqual(actual, expected, "total=\(pair.total) min=\(pair.min) cores=\(cores)")
            } else {
                // All cores branch
                XCTAssertEqual(actual, cores, "total=\(pair.total) min=\(pair.min) cores=\(cores)")
            }
        }

        XCTAssertNotEqual(ThreadUtils.processCount(totalTaskCount: 11, minTaskPerThread: 10), cores)
    }

    // MARK: - Helpers

    private struct DecodedEntry: Codable, Equatable {
        let name: String?
        let changeNumber: Int64?
        let status: String?
        let trafficType: String?
        let sets: [String]?
        let json: String
    }

    private func entry(_ split: Split) -> DecodedEntry {
        var status: String?
        switch split.status {
        case .active?: status = "active"
        case .archived?: status = "archived"
        default: status = nil
        }
        return DecodedEntry(name: split.name,
                            changeNumber: split.changeNumber,
                            status: status,
                            trafficType: split.trafficTypeName,
                            sets: split.sets?.sorted(),
                            json: split.json)
    }

    private func loadFlags(_ count: Int) throws -> [String] {
        let data = try XCTUnwrap(FileHelper.loadFileData(sourceClass: self,
                                                         name: "decoder_flags_\(count)", type: "json"))
        return try JSONDecoder().decode([String].self, from: data)
    }

    private func loadGolden(_ count: Int) throws -> [DecodedEntry] {
        let data = try XCTUnwrap(FileHelper.loadFileData(sourceClass: self,
                                                         name: "decoder_golden_\(count)", type: "json"))
        return try JSONDecoder().decode([DecodedEntry].self, from: data)
    }

    private func taskCountLogs() -> [Int] {
        printerStub.logsSnapshot().compactMap { line -> Int? in
            guard let range = line.range(of: "Task count for parallel decoding: ") else {
                return nil
            }
            return Int(String(line[range.upperBound...].prefix(while: { $0.isNumber })))
        }
    }

    private func corruptPayloadInput() -> [String] {
        return [
            #"{"name":"ok_1","trafficTypeName":"user","status":"ACTIVE","killed":false}"#,
            #"{"name":"broken_json","trafficTypeName":"user","status":"ACTIVE","killed":false"#,
            #"{"name":"ok_2","trafficTypeName":"account","status":"ARCHIVED","killed":true,"sets":["set_a"]}"#,
            #"{"trafficTypeName":"user","status":"ACTIVE","killed":false}"#,
            #"{"name":"ok_3","trafficTypeName":"user","status":"ACTIVE","killed":false,"sets":[]}"#,
            #"{"name":"no_killed","trafficTypeName":"user","status":"ACTIVE"}"#,
            #"{"name":"ok_4","trafficTypeName":"user","status":"ACTIVE","killed":false}"#,
            #"{"name":"bad_status","trafficTypeName":"user","status":"BOGUS","killed":false}"#,
            #"{"name":"ok_5","trafficTypeName":"account","status":"ACTIVE","killed":false}"#,
            #"{"name":"no_traffic","status":"ACTIVE","killed":false}"#,
            #"{"name":"ok_6","trafficTypeName":"user","status":"ARCHIVED","killed":false,"sets":["set_b"]}"#,
            #"["not","an","object"]"#
        ]
    }

    func loadJsonSplits(times: Int = 1) -> [String] {
        var splits = [String]()
        for _ in 0..<times {
            let news = FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_1")!.splits
            splits.append(contentsOf: news.compactMap { split in
                split.name = UUID().uuidString
                split.killed = false
                return try? Json.encodeToJson(split)
            })
        }
        return splits
    }

}

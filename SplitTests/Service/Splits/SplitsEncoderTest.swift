//
//  SplitsEncoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitsEncoderTest: XCTestCase {

    var encoder: SplitsParallelEncoder!

    func testDecodeOneThread() throws {

        // Less than 15 will use 1 thread
        let splits = Array(loadSplits()[..<10])

        encoder = SplitsParallelEncoder(minTaskPerThread: 15)
        let jsons = encoder.encode(splits)

        XCTAssertEqual(splits.count, jsons.count)
    }

    func testDecodeTwoThread() throws {

        // Less than 30 will use 2 threads
        let splits = Array(loadSplits()[..<30])

        encoder = SplitsParallelEncoder(minTaskPerThread: 15)
        let jsons = encoder.encode(splits)

        XCTAssertEqual(splits.count, jsons.count)
    }

    func testDecodeMultiThread() throws {
        let splits = loadSplits(times: 10)
        encoder = SplitsParallelEncoder(minTaskPerThread: 10)
        let jsons = encoder.encode(splits)

        XCTAssertEqual(splits.count, jsons.count)
    }

    // MARK: - Round-trip characterisation (issue 17)
    // Expected values are roundtrip_golden_100.json, dumped from the unmodified production
    // code at ea3e036d. `json` is canonicalised (sorted keys, sorted sets) because
    // Set<String> encodes in a per-process hash order.

    func test_roundTrip_insertOrUpdate_matchesFixture() throws {
        let helper = makeHelper()
        let dao = CoreDataSplitDao(coreDataHelper: helper, timeChecker: TimeChecker.forTesting())

        dao.insertOrUpdate(splits: try decodeFixture100())

        // insertOrUpdate writes on the dao queue; getAll runs on the same queue, so it observes the write.
        let actual = readBack(dao)
        let golden = try loadRoundTripGolden()
        XCTAssertEqual(actual.count, 100)
        XCTAssertEqual(golden.count, 100)
        XCTAssertEqual(actual, golden)
    }

    func test_roundTrip_transactionalInsertOrUpdate_matchesFixture() throws {
        let helper = makeHelper()
        let dao = CoreDataSplitDao(coreDataHelper: helper, timeChecker: TimeChecker.forTesting())
        let decoded = try decodeFixture100()

        // Mirrors PersistentSplitsStorage.update: transactional write, then one explicit save.
        helper.perform {
            dao.transactionalInsertOrUpdate(splits: decoded)
            do {
                try helper.saveWithErrorHandling()
            } catch {
                XCTFail("transactional save failed: \(error)")
            }
        }
        // Serial queue: this returns only after the transaction above has run.
        helper.performAndWait {}

        let actual = readBack(dao)
        let golden = try loadRoundTripGolden()
        XCTAssertEqual(actual.count, 100)
        XCTAssertEqual(golden.count, 100)
        XCTAssertEqual(actual, golden)
    }

    private struct RoundTripEntry: Codable, Equatable {
        let name: String?
        let status: String?
        let trafficType: String?
        let sets: [String]?
        let killed: Bool?
        let json: String
    }

    private func makeHelper() -> CoreDataHelper {
        let queue = DispatchQueue(label: "roundtrip test \(UUID().uuidString)")
        return IntegrationCoreDataHelper.get(databaseName: "roundtrip-\(UUID().uuidString)",
                                             dispatchQueue: queue)
    }

    private func decodeFixture100() throws -> [Split] {
        let data = try XCTUnwrap(FileHelper.loadFileData(sourceClass: self,
                                                         name: "decoder_flags_100", type: "json"))
        let flags = try JSONDecoder().decode([String].self, from: data)
        XCTAssertEqual(flags.count, 100)
        return SplitsSerialDecoder(cipher: nil).decode(flags)
    }

    private func readBack(_ dao: SplitDao) -> [RoundTripEntry] {
        return dao.getAll()
            .map { roundTripEntry($0) }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    private func roundTripEntry(_ split: Split) -> RoundTripEntry {
        var status: String?
        switch split.status {
        case .active?: status = "active"
        case .archived?: status = "archived"
        default: status = nil
        }
        return RoundTripEntry(name: split.name,
                              status: status,
                              trafficType: split.trafficTypeName,
                              sets: split.sets?.sorted(),
                              killed: split.killed,
                              json: canonicalJson(split.json))
    }

    private func canonicalJson(_ json: String) -> String {
        guard var obj = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any] else {
            return json
        }
        if let sets = obj["sets"] as? [String] {
            obj["sets"] = sets.sorted()
        }
        let data = (try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    private func loadRoundTripGolden() throws -> [RoundTripEntry] {
        let data = try XCTUnwrap(FileHelper.loadFileData(sourceClass: self,
                                                         name: "roundtrip_golden_100", type: "json"))
        return try JSONDecoder().decode([RoundTripEntry].self, from: data)
    }

    func loadSplits(times: Int = 1) -> [Split] {
        var splits = [Split]()
        for _ in 0..<times {
            let news = FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_1")!.splits
            splits.append(contentsOf: news.map { split in
                split.name = UUID().uuidString
                return split
            })
        }
        return splits
    }
}


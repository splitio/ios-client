//
//  SplitsDecoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SplitsDecoderTest: XCTestCase {
    func testDecodeOneThread() throws {
        let decoder = SplitsParallelDecoder(minTaskPerThread: 15)
        let jsons = Array(loadJsonSplits()[..<10])

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    func testDecodeTwoThreads() throws {
        let decoder = SplitsParallelDecoder(minTaskPerThread: 15)
        let jsons = Array(loadJsonSplits()[0 ..< 30])

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    func testDecodeMultiThreads() throws {
        let decoder = SplitsParallelDecoder(minTaskPerThread: 10)
        let jsons = loadJsonSplits(times: 10)

        let splits = decoder.decode(jsons)

        XCTAssertEqual(jsons.count, splits.count)
        XCTAssertEqual(String(describing: type(of: splits[0])), "SplitDTO")
    }

    func loadJsonSplits(times: Int = 1) -> [String] {
        var splits = [String]()
        for _ in 0 ..< times {
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

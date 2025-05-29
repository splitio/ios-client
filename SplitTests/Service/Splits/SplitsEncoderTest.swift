//
//  SplitsEncoderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

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

    func loadSplits(times: Int = 1) -> [Split] {
        var splits = [Split]()
        for _ in 0 ..< times {
            let news = FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_1")!.splits
            splits.append(contentsOf: news.map { split in
                split.name = UUID().uuidString
                return split
            })
        }
        return splits
    }
}

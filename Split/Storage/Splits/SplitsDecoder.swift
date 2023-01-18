//
//  SplitsCoder.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

struct ParsedSplit: Codable {
    let split: Split
    let json: String
}

protocol SplitsDecoder {
    func decode(_ list: [String]) -> [ParsedSplit]
}

struct SplitsParallelDecoder: SplitsDecoder {

    func decode(_ list: [String]) -> [ParsedSplit] {

        if list.count == 0 {
            return []
        }
        Logger.v("Using parallel decoding for \(list.count) splits")
        let serialDecoder = SplitsSerialDecoder()
        var splits = [ParsedSplit]()
        let dataQueue = DispatchQueue(label: "split-parallel-parsing-data",
                                      target: DispatchQueue(label: "split-parallel-parsing-data-conc",
                                                            attributes: .concurrent))
        let queue = OperationQueue()
        let taskCount = ProcessInfo.processInfo.processorCount
        let chunkSize = Int(list.count / taskCount)
        Logger.v("Task count for parallel decoding: \(taskCount)")
        Logger.v("Chunck size for parallel decoding: \(chunkSize)")
        list.chunked(into: chunkSize).forEach { chunk in
            queue.addOperation {
                let parsed = serialDecoder.decode(chunk)
                dataQueue.sync {
                    splits.append(contentsOf: parsed)
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        print("Parsed count: \(splits.count)")
        return splits
    }
}

struct SplitsSerialDecoder: SplitsDecoder {
    func decode(_ list: [String]) -> [ParsedSplit] {
        if list.count == 0 {
            return []
        }
        return list.compactMap { json in
            guard let split = try? Json.encodeFrom(json: json, to: Split.self) else {
                return nil
            }
            return ParsedSplit(split: split, json: json)
        }
    }
}

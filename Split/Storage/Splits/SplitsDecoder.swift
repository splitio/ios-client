//
//  SplitsCoder.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol SplitsDecoder {
    func decode(_ list: [String]) -> [Split]
}

struct SplitsParallelDecoder: SplitsDecoder {

    func decode(_ list: [String]) -> [Split] {

        if list.count == 0 {
            return []
        }
        Logger.v("Using parallel decoding for \(list.count) splits")
        let serialDecoder = SplitsSerialDecoder()
        var splits = [Split]()
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
    func decode(_ list: [String]) -> [Split] {
        if list.count == 0 {
            return []
        }
//        Logger.v("Parsing \(list.count) splits")
        return list.compactMap { try? Json.encodeFrom(json: $0, to: Split.self) }
    }
}

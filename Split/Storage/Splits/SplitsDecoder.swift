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
        let serialDecoder = SplitsSerialDecoder()
        var splits = [Split]()
        let dataQueue = DispatchQueue(label: "split-parallel-parsing-data",
                                      target: DispatchQueue(label: "split-parallel-parsing-data-conc",
                                                            attributes: .concurrent))
        let queue = OperationQueue()
        let taskCount = ProcessInfo.processInfo.processorCount
        let chunkSize = Int(list.count / taskCount)
        list.chunked(into: chunkSize).forEach { chunk in
            var parsed = [Split]()
            queue.addOperation {
                parsed = serialDecoder.decode(chunk)
            }
            dataQueue.sync {
                splits.append(contentsOf: parsed)
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return splits
    }

    func decodeChunk(_ list: [String]) -> [Split] {
        return list.compactMap { try? Json.encodeFrom(json: $0, to: Split.self) }
    }
}

struct SplitsSerialDecoder: SplitsDecoder {
    func decode(_ list: [String]) -> [Split] {
        return list.compactMap { try? Json.encodeFrom(json: $0, to: Split.self) }
    }
}

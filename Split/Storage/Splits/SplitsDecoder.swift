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
    private var minTaskPerThread: Int

    init(minTaskPerThread: Int = 10) {
        self.minTaskPerThread = minTaskPerThread
    }

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

        let taskCount = ThreadUtils.processCount(totalTaskCount: list.count, minTaskPerThread: minTaskPerThread)
        let chunkSize = Int(list.count / taskCount)
        Logger.v("Task count for parallel decoding: \(taskCount)")
        Logger.v("Chunck size for parallel decoding: \(chunkSize)")

        if taskCount == 1 {
            return serialDecoder.decode(list)
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = taskCount
        list.chunked(into: chunkSize).forEach { chunk in
            queue.addOperation {
                let parsed = serialDecoder.decode(chunk)
                dataQueue.sync {
                    splits.append(contentsOf: parsed)
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return splits
    }
}

struct SplitsSerialDecoder: SplitsDecoder {
    // TODO: Inyect cipher on constructor
    private var aesCipher: Cipher? = nil//DefaultCipher()
    // TODO: Replace with a good random key generation
    private let aesKey = ServiceConstants.aesKeyForPoC
    func decode(_ list: [String]) -> [Split] {
        if list.count == 0 {
            return []
        }
        // decoding one by one to avoid losing all
        // data if one parsing fails
        return list.compactMap { json in
            do {
                let plainJson = aesCipher?.decrypt(json, key: aesKey) ?? json
                return try Json.encodeFrom(json: plainJson, to: Split.self)
            } catch {
                Logger.v("Failed decoding split json: \(json)")
            }
            return nil
        }
    }
}

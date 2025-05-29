//
//  SplitsCoder.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol SplitsEncoder {
    func encode(_ list: [Split]) -> [String: String]
}

struct SplitsParallelEncoder: SplitsEncoder {
    private var minTaskPerThread: Int
    private let serialEncoder: SplitsEncoder

    init(minTaskPerThread: Int = 10, cipher: Cipher? = nil) {
        self.minTaskPerThread = minTaskPerThread
        self.serialEncoder = SplitsSerialEncoder(cipher: cipher)
    }

    // Returns Name: Json
    func encode(_ list: [Split]) -> [String: String] {
        if list.isEmpty {
            return [:]
        }
        Logger.v("Using parallel encoding for \(list.count) feature flags")

        var splitsJson = [String: String]()
        let dataQueue = DispatchQueue(
            label: "split-parallel-encoding-data",
            target: DispatchQueue(
                label: "split-parallel-encoding-data-conc",
                attributes: .concurrent))

        let taskCount = ThreadUtils.processCount(totalTaskCount: list.count, minTaskPerThread: minTaskPerThread)
        let chunkSize = Int(list.count / taskCount)
        Logger.v("Task count for parallel encoding: \(taskCount)")
        Logger.v("Chunck size for parallel encoding: \(chunkSize)")

        if taskCount == 1 {
            return serialEncoder.encode(list)
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = taskCount
        list.chunked(into: chunkSize).forEach { splits in
            queue.addOperation {
                let parsed = serialEncoder.encode(splits)
                dataQueue.sync {
                    splitsJson.merge(parsed, uniquingKeysWith: { _, new in new })
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return splitsJson
    }
}

struct SplitsSerialEncoder: SplitsEncoder {
    private var cipher: Cipher?

    init(cipher: Cipher?) {
        self.cipher = cipher
    }

    func encode(_ list: [Split]) -> [String: String] {
        if list.isEmpty {
            return [:]
        }
        // Parsing one by one to avoid losing all
        // data if one parsing fails
        var result = [String: String]()
        list.forEach { split in
            do {
                if let name = cipher?.encrypt(split.name) ?? split.name {
                    let json = try Json.encodeToJson(split)
                    result[name] = cipher?.encrypt(json) ?? json
                }
            } catch {
                Logger.v("Failed encoding feature flag json: \(split.name ?? "empty name!")")
            }
        }
        return result
    }
}

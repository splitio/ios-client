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
    private let serialDecoder: SplitsSerialDecoder
    init(minTaskPerThread: Int = 10, cipher: Cipher? = nil) {
        self.minTaskPerThread = minTaskPerThread
        self.serialDecoder = SplitsSerialDecoder(cipher: cipher)
    }

    func decode(_ list: [String]) -> [Split] {
        if list.isEmpty {
            return []
        }

        Logger.v("Using parallel decoding for \(list.count) splits")
        let start = Date.nowMillis()
        var splits = [Split]()
        let dataQueue = DispatchQueue(
            label: "split-parallel-parsing-data",
            target: DispatchQueue(
                label: "split-parallel-parsing-data-conc",
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
        TimeChecker.logInterval("Time to parse loaded splits", startTime: start)
        return splits
    }
}

struct SplitsSerialDecoder: SplitsDecoder {
    private var cipher: Cipher?

    init(cipher: Cipher?) {
        self.cipher = cipher
    }

    func decode(_ list: [String]) -> [Split] {
        if list.isEmpty {
            return []
        }
        // decoding one by one to avoid losing all
        // data if one parsing fails
        return list.compactMap { json in
            do {
                let plainJson = cipher?.decrypt(json) ?? json
                return try self.getSplit(plainJson)
//                return try Json.decodeFrom(json: plainJson, to: Split.self)
            } catch {
                Logger.v("Failed decoding feature flag json: \(json)")
            }
            return nil
        }
    }

    func getSplit(_ json: String) throws -> Split {
        guard let data = json.data(using: .utf8) else {
            throw GenericError.unknown(message: "parsing error")
        }

        let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let name = jsonObj?["name"] as? String
        let trafficType = jsonObj?["trafficTypeName"] as? String
        let status = jsonObj?["status"] as? String
        let setsArray = jsonObj?["sets"] as? [String]
        let killed = jsonObj?["killed"] as? Bool
        let sets = setsArray != nil ? Set<String>(setsArray ?? []) : nil

        if let name = name, let trafficType = trafficType, let status = status,
           let statusValue = Status.enumFromString(string: status),
           let killed = killed {
            return Split(
                name: name,
                trafficType: trafficType,
                status: statusValue,
                sets: sets,
                json: json,
                killed: killed)
        }

        Logger.e("Error decoding split")
        throw GenericError.unknown(message: "Error decoding split")
    }
}

//
//  Splitter.swift
//  Split
//
//  Created by Natalia  Stele on 11/7/17.
//

import Foundation

enum Algorithm: Int {
    case legacy = 1
    case murmur3 = 2
}

protocol SplitterProtocol {
    func getTreatment(key: Key, seed: Int, attributes: [String: Any]?,
                      partions: [Partition]?, algo: Algorithm) -> String
    func getBucket(seed: Int, key: String, algo: Algorithm) -> Int64
}

class Splitter: SplitterProtocol {

    static let shared: Splitter = {
        let instance = Splitter()
        return instance
    }()

    func getTreatment(key: Key, seed: Int, attributes: [String: Any]?,
                      partions: [Partition]?, algo: Algorithm) -> String {

        var accumulatedSize: Int = 0

        let bucket: Int64 = getBucket(seed: seed, key: key.bucketingKey ?? key.matchingKey, algo: algo)
        if let splitPartitions = partions {
            for partition in splitPartitions {
                accumulatedSize += partition.size ?? 0
                if bucket <= accumulatedSize {
                    return partition.treatment ?? SplitConstants.control
                }
            }
        }
        return SplitConstants.control
    }

    func getBucket(seed: Int, key: String, algo: Algorithm) -> Int64 {
        let hashCode: Int64 = self.hashCode(seed: seed, key: key, algo: algo)
        var reminder = hashCode  % 100
        if algo == Algorithm.legacy {
            reminder = abs(reminder)
        }
        return Int64(reminder) + Int64(1)
    }

     func hashCode(seed: Int, key: String, algo: Algorithm) -> Int64 {
        switch algo {
        case .murmur3:
            return Int64(truncatingIfNeeded: Murmur3Hash.hashString(key, UInt32(truncatingIfNeeded: seed)))
        default:
            return LegacyHash.getHash(key, Int32(truncatingIfNeeded: seed))
        }
    }
}

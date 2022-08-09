//
//  ImpressionsObserver.swift
//  Split
//
//  Created by Javier Avrudsky on 15/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct ImpressionsObserver {
    private let cache: LRUCache<UInt32, Int64>

    init(size: Int) {
        cache = LRUCache(capacity: size)
    }

    func testAndSet(impression: KeyImpression) -> Int64? {
        let hash = ImpressionHasher.process(impression: impression)
        let previous = cache.element(for: hash)
        cache.set(impression.time, for: hash)
        guard let previousTime = previous else {
            return nil
        }
        return min(previousTime, impression.time)
    }

    func stop() {
        cache.clear()
    }
}

struct ImpressionHasher {

    private static let kSeed: UInt32 = 0
    private static let kOffset: Int64 = 0
    private static let kUnknown = "UNKNOWN"

    static func process(impression: KeyImpression) -> UInt32 {
        let data = "\(sanitize(impression.keyName)):\(sanitize(impression.featureName))" +
            ":\(sanitize(impression.treatment)):" + "\(sanitize(impression.label)):\(sanitize(impression.changeNumber))"
        return Murmur3Hash.hashString(data, Self.kSeed)
    }

    private static func sanitize(_ value: Any?) -> String {
        guard let value = value else {
            return kUnknown
        }
        return "\(value)"
    }
}

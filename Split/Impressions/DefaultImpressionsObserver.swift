//
//  ImpressionsObserver.swift
//  Split
//
//  Created by Javier Avrudsky on 15/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol ImpressionsObserver {
    func testAndSet(impression: KeyImpression) -> Int64?
    func clear()
    func saveHashes()
}

struct DefaultImpressionsObserver: ImpressionsObserver {
    private let storage: HashedImpressionsStorage

    init(storage: HashedImpressionsStorage) {
        self.storage = storage
        storage.loadFromDb()
    }

    func testAndSet(impression: KeyImpression) -> Int64? {
        // impression with properties are considered unique
        if impression.properties != nil {
            return nil
        }

        let hash = ImpressionHasher.process(impression: impression)
        let previous = storage.get(for: hash)
        storage.set(impression.time, for: hash)
        guard let previousTime = previous else {
            return nil
        }
        return min(previousTime, impression.time)
    }

    func clear() {
        storage.clear()
    }

    func saveHashes() {
        storage.save()
    }
}

enum ImpressionHasher {
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

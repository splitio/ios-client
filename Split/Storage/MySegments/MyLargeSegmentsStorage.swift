//
//  MyLargeSegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class MyLargeSegmentsStorage: MySegmentsStorage {

    private(set) var changeNumber: Int64 = -1
    private var inMemoryMySegments: SynchronizedDictionarySet<String, String> = SynchronizedDictionarySet()
    private let persistenStorage: PersistentMySegmentsStorage

    var keys: Set<String> {
        return inMemoryMySegments.keys
    }

    init(persistentMySegmentsStorage: PersistentMySegmentsStorage) {
        persistenStorage = persistentMySegmentsStorage
    }

    func loadLocal(forKey key: String) {
        inMemoryMySegments.set(Set(persistenStorage.getSnapshot(forKey: key)), forKey: key)
    }

    func getAll(forKey key: String) -> Set<String> {
        return inMemoryMySegments.values(forKey: key) ?? Set<String>()
    }

    func set(_ change: SegmentChange, forKey key: String) {
        let segments = change.segments
        inMemoryMySegments.set(segments.asSet(), forKey: key)
        persistenStorage.set(segments, forKey: key)
    }

    func clear(forKey key: String) {
        inMemoryMySegments.removeValues(forKey: key)
        persistenStorage.set([String](), forKey: key)
    }

    func destroy() {
        inMemoryMySegments.removeAll()
    }

    func getCount(forKey key: String) -> Int {
        return inMemoryMySegments.count(forKey: key)
    }

    func getCount() -> Int {
        let keys = inMemoryMySegments.keys
        var count = 0
        for key in keys {
            count+=(inMemoryMySegments.values(forKey: key)?.count ?? 0)
        }
        return count
    }
}

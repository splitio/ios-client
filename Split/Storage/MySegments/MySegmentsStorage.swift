//
//  MySegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol MySegmentsStorage: RolloutDefinitionsCache {
    var keys: Set<String> { get }
    func loadLocal(forKey key: String)
    func changeNumber(forKey key: String) -> Int64?
    func lowerChangeNumber() -> Int64
    func getAll(forKey key: String) -> Set<String>
    func set(_ change: SegmentChange, forKey key: String)
    func clear(forKey key: String)
    func destroy()
    func getCount(forKey key: String) -> Int
    func getCount() -> Int
}

class DefaultMySegmentsStorage: MySegmentsStorage {
    private var inMemoryMySegments: SynchronizedDictionarySet<String, String> = SynchronizedDictionarySet()
    private let persistenStorage: PersistentMySegmentsStorage

    var keys: Set<String> {
        return inMemoryMySegments.keys
    }

    init(persistentMySegmentsStorage: PersistentMySegmentsStorage) {
        self.persistenStorage = persistentMySegmentsStorage
    }

    func loadLocal(forKey key: String) {
        let segments = persistenStorage.getSnapshot(forKey: key)?.segments.compactMap { $0.name } ?? []
        inMemoryMySegments.set(segments.asSet(), forKey: key)
    }

    func changeNumber(forKey key: String) -> Int64? {
        return -1
    }

    func lowerChangeNumber() -> Int64 {
        return -1
    }

    func getAll(forKey key: String) -> Set<String> {
        return inMemoryMySegments.values(forKey: key) ?? Set<String>()
    }

    func set(_ change: SegmentChange, forKey key: String) {
        let names = change.segments.compactMap { $0.name }
        inMemoryMySegments.set(names.asSet(), forKey: key)
        persistenStorage.set(change, forKey: key)
    }

    func clear(forKey key: String) {
        inMemoryMySegments.removeValues(forKey: key)
        persistenStorage.set(SegmentChange.empty(), forKey: key)
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
            count += (inMemoryMySegments.values(forKey: key)?.count ?? 0)
        }
        return count
    }

    func clear() {
        inMemoryMySegments.removeAll()
        persistenStorage.deleteAll()
    }
}

//
//  MyLargeSegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Mar-2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class MyLargeSegmentsStorage: MySegmentsStorage {

    private var inMemorySegments: SynchronizedDictionary<String, SegmentChange> = SynchronizedDictionary()
    private let persistentStorage: PersistentMyLargeSegmentsStorage
    private let defaultChangeNumber = ServiceConstants.defaultMlsChangeNumber

    var keys: Set<String> {
        return inMemorySegments.keys
    }

    init(persistentStorage: PersistentMyLargeSegmentsStorage) {
        self.persistentStorage = persistentStorage
    }

    func loadLocal(forKey key: String) {
        let change = persistentStorage.getSnapshot(forKey: key) ?? SegmentChange.empty()
        inMemorySegments.setValue(change, forKey: key)
    }

    func changeNumber(forKey key: String) -> Int64? {
        return inMemorySegments.value(forKey: key)?.changeNumber ?? defaultChangeNumber
    }

    func getAll(forKey key: String) -> Set<String> {
        return inMemorySegments.value(forKey: key)?.segments.asSet() ?? Set<String>()
    }

    func set(_ change: SegmentChange, forKey key: String) {
        inMemorySegments.setValue(change, forKey: key)
        persistentStorage.set(change, forKey: key)
    }

    func clear(forKey key: String) {
        let clearChange = SegmentChange(segments: [])
        inMemorySegments.setValue(clearChange, forKey: key)
        persistentStorage.set(clearChange, forKey: key)
    }

    func destroy() {
        inMemorySegments.removeAll()
    }

    func getCount(forKey key: String) -> Int {
        return inMemorySegments.value(forKey: key)?.segments.count ?? 0
    }

    func getCount() -> Int {
        let keys = inMemorySegments.keys
        var count = 0
        for key in keys {
            count+=(inMemorySegments.value(forKey: key)?.segments.count ?? 0)
        }
        return count
    }
}

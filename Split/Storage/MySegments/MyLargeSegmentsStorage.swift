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
    private let persistentStorage: PersistentMySegmentsStorage
    private let defaultChangeNumber = ServiceConstants.defaultSegmentsChangeNumber
    private let syncQueue: DispatchQueue
    private let syncQueueKey = DispatchSpecificKey<Void>()
    private let generalInfoStorage: GeneralInfoStorage

    var keys: Set<String> {
        return inMemorySegments.keys
    }

    init(persistentStorage: PersistentMySegmentsStorage, generalInfoStorage: GeneralInfoStorage) {
        self.persistentStorage = persistentStorage
        self.generalInfoStorage = generalInfoStorage
        self.syncQueue = DispatchQueue(label: "split-large-segments-storage")
        syncQueue.setSpecific(key: syncQueueKey, value: ())
    }

    func loadLocal(forKey key: String) {
        safeSync {
            let change = persistentStorage.getSnapshot(forKey: key) ?? SegmentChange.empty()
            inMemorySegments.setValue(change, forKey: key)
        }
    }

    func changeNumber(forKey key: String) -> Int64? {
        return inMemorySegments.value(forKey: key)?.changeNumber ?? defaultChangeNumber
    }

    func lowerChangeNumber() -> Int64 {
        return inMemorySegments.all.values.compactMap { $0.changeNumber }.min() ?? -1
    }

    func getAll(forKey key: String) -> Set<String> {
        return inMemorySegments.value(forKey: key)?.segments.compactMap { $0.name }.asSet() ?? Set<String>()
    }

    func set(_ change: SegmentChange, forKey key: String) {
        safeSync {
            inMemorySegments.setValue(change, forKey: key)
            persistentStorage.set(change, forKey: key)
        }
    }

    func clear(forKey key: String) {
        safeSync {
            let clearChange = SegmentChange(segments: [])
            inMemorySegments.setValue(clearChange, forKey: key)
            persistentStorage.set(clearChange, forKey: key)
        }
    }

    func destroy() {
        inMemorySegments.removeAll()
    }

    func getCount(forKey key: String) -> Int {
        return inMemorySegments.value(forKey: key)?.segments.count ?? 0
    }

    func getCount() -> Int {
        safeSync {
            let keys = inMemorySegments.keys
            var count = 0
            for key in keys {
                count+=(inMemorySegments.value(forKey: key)?.segments.count ?? 0)
            }
            return count
        }
    }

    func clear() {
        inMemorySegments.removeAll()
        persistentStorage.deleteAll()
    }

    // if already being executed in the queue, do not dispatch to it
    private func safeSync<T>(_ block: () -> T) -> T {
        if DispatchQueue.getSpecific(key: syncQueueKey) != nil {
            return block()
        } else {
            return syncQueue.sync(execute: block)
        }
    }
    
    // MARK: For Network Traffic Optimization
    func isUsingSegments() -> Bool {
        (generalInfoStorage.getSegmentsInUse() ?? 0) > 0
    }
}

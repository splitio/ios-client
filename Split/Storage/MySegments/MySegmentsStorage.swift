//
//  MySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol MySegmentsStorage {
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ segments: [String])
    func clear()
}

class DefaultMySegmentsStorage: MySegmentsStorage {

    var inMemoryMySegments: ConcurrentSet<String>
    let persistenStorage: PersistentMySegmentsStorage

    init(persistentMySegmentsStorage: PersistentMySegmentsStorage) {
        persistenStorage = persistentMySegmentsStorage
        inMemoryMySegments = ConcurrentSet<String>()
    }

    func loadLocal() {
        inMemoryMySegments.set(persistenStorage.getSnapshot())
    }

    func getAll() -> Set<String> {
        return inMemoryMySegments.all
    }

    func set(_ segments: [String]) {
        inMemoryMySegments.set(segments)
        persistenStorage.set(segments)
    }

    func clear() {
        inMemoryMySegments.removeAll()
        persistenStorage.set([String]())
    }
}

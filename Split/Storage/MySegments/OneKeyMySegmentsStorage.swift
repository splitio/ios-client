//
//  MySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Gonna be replaced by MySegmentsStorage and ByKeyMySegmentsStorage")
protocol OneKeyMySegmentsStorage {
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ segments: [String])
    func clear()
    func destroy()
    func getCount() -> Int
}

@available(*, deprecated, message: "Gonna be replaced by MySegmentsStorage and ByKeyMySegmentsStorage")
class DefaultOneKeyMySegmentsStorage: OneKeyMySegmentsStorage {

    private var inMemoryMySegments: ConcurrentSet<String>
    private let persistenStorage: OneKeyPersistentMySegmentsStorage

    init(persistentMySegmentsStorage: OneKeyPersistentMySegmentsStorage) {
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

    func destroy() {
        inMemoryMySegments.removeAll()
    }

    func getCount() -> Int {
        return inMemoryMySegments.count
    }
}

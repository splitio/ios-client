//
//  PersistentMyLargeSegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentMySegmentsStorageMock: PersistentMySegmentsStorage {
    var persistedSegments = [String: SegmentChange]()

    func set(_ change: SegmentChange, forKey key: String) {
        persistedSegments[key] = change
    }

    func getSnapshot(forKey key: String) -> SegmentChange? {
        return persistedSegments[key]
    }

    func close() {}

    func deleteAll() {
        persistedSegments.removeAll()
    }
}

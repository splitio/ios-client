//
//  PersistentMySegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentMySegmentsStorageStub: PersistentMySegmentsStorage {
    var persistedSegments = [String: [String]]()

    func set(_ segments: [String], forKey key: String) {
        persistedSegments[key] = segments
    }

    func getSnapshot(forKey key: String) -> [String] {
        return persistedSegments[key] ?? [String]()
    }

    func close() {
    }
}

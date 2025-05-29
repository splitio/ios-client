//
//  HashedImpressionsMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 22/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class HashedImpressionsStorageMock: HashedImpressionsStorage {
    let queue = DispatchQueue(label: "test", target: .global())
    var items = [UInt32: Int64]()

    var loadDbCalled = false
    func loadFromDb() {
        loadDbCalled = true
    }

    var saveCalled = false
    func save() {
        saveCalled = true
    }

    func set(_ time: Int64, for hash: UInt32) {
        queue.sync {
            items[hash] = time
        }
    }

    func get(for hash: UInt32) -> Int64? {
        var time: Int64?
        queue.sync {
            time = items[hash]
        }
        return time
    }

    func clear() {
        queue.sync {
            items.removeAll()
        }
    }
}

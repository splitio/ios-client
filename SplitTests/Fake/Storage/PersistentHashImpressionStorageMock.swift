//
//  PersistentHashImpressionStorageMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 22/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentHashedImpressionStorageMock: PersistentHashedImpressionsStorage, @unchecked Sendable {

    let queue = DispatchQueue(label: "test", target: .global())
    var items = [UInt32: HashedImpression]()

    func update(_ hashes: [HashedImpression]) {
        queue.sync {
            for hash in hashes {
                items[hash.impressionHash] = hash
            }
        }
    }

    func delete(_ hashes: [HashedImpression]) {
        queue.sync {
            for hash in hashes {
                items[hash.impressionHash] = nil
            }
        }
    }

    func getAll() -> [HashedImpression] {
        return items.values.map { $0 as HashedImpression }
    }
}

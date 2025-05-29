//
//  HashedImpressionDaoMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 21/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class HashedImpressionDaoMock: HashedImpressionDao {
    var items = [UInt32: HashedImpression]()
    func update(_ hashes: [HashedImpression]) {
        hashes.forEach {
            items[$0.impressionHash] = $0
        }
    }

    func delete(_ hashes: [HashedImpression]) {
        items.removeAll()
    }

    func getAll() -> [HashedImpression] {
        return items.values.map { $0 as HashedImpression }
    }
}

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
    var items = [HashedImpression]()

    func getAll() -> [HashedImpression] {
        return items
    }

    func set(_ hashes: [HashedImpression]) {
        items.removeAll()
        items.append(contentsOf: hashes)
    }


}

//
//  UniqueKeysDaoStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class UniqueKeyDaoStub: UniqueKeyDao {
    var insertedKeys = [UniqueKey]()
    var getByKeys = [UniqueKey]()
    var updatedStatus = [String: Int32]()
    var updatedCount = [String: Int16]()
    var updatedKeys = [String: UniqueKey]()
    var deletedKeys = [String]()

    func insert(_ key: UniqueKey) {
        insertedKeys.append(key)
    }

    func insert(_ keys: [UniqueKey]) {
        insertedKeys.append(contentsOf: keys)
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [UniqueKey] {
        return getByKeys
    }

    func update(ids: [String], newStatus: Int32, incrementSentCount: Bool) {
        ids.forEach {
            updatedStatus[$0] = newStatus
        }
    }

    func delete(_ events: [String]) {
        deletedKeys.append(contentsOf: events)
    }
}

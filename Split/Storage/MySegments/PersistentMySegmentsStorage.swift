//
//  PersistentMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentMySegmentsStorage {
    func set(_ change: SegmentChange, forKey key: String)
    func getSnapshot(forKey key: String) -> SegmentChange?
    func deleteAll()
}

class PersistentSegmentsStorage: PersistentMySegmentsStorage {

    private let dao: MySegmentsDao

    init(dao: MySegmentsDao) {
        self.dao = dao
    }

    func set(_ change: SegmentChange, forKey key: String) {
        dao.update(userKey: key, change: change)
    }

    func getSnapshot(forKey key: String) -> SegmentChange? {
        return dao.getBy(userKey: key)
    }

    func deleteAll() {
        dao.deleteAll()
    }
}

class DefaultPersistentMySegmentsStorage: PersistentSegmentsStorage {
    init(database: SplitDatabase) {
        super.init(dao: database.mySegmentsDao)
    }
}

class DefaultPersistentMyLargeSegmentsStorage: PersistentSegmentsStorage {
    init(database: SplitDatabase) {
        super.init(dao: database.myLargeSegmentsDao)
    }
}

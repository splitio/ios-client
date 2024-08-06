//
//  PersistentMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentMyLargeSegmentsStorage {
    func set(_ change: SegmentChange, forKey key: String)
    func getSnapshot(forKey key: String) -> SegmentChange?
}

class DefaultPersistentMyLargeSegmentsStorage: PersistentMyLargeSegmentsStorage {

    private let myLargeSegmentsDao: MyLargeSegmentsDao

    init(database: SplitDatabase) {
        self.myLargeSegmentsDao = database.myLargeSegmentsDao
    }

    func set(_ change: SegmentChange, forKey key: String) {
        myLargeSegmentsDao.update(userKey: key, change: change)
    }

    func getSnapshot(forKey key: String) -> SegmentChange? {
        return myLargeSegmentsDao.getBy(userKey: key)
    }
}

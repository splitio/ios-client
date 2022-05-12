//
//  PersistentMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentMySegmentsStorage {
    func set(_ segments: [String], forKey key: String)
    func getSnapshot(forKey key: String) -> [String]
}

class DefaultPersistentMySegmentsStorage: PersistentMySegmentsStorage {

    private let mySegmentsDao: MySegmentsDao

    init(database: SplitDatabase) {
        self.mySegmentsDao = database.mySegmentsDao
    }

    func set(_ segments: [String], forKey key: String) {
        mySegmentsDao.update(userKey: key, segmentList: segments)
    }

    func getSnapshot(forKey key: String) -> [String] {
        return mySegmentsDao.getBy(userKey: key)
    }
}

//
//  DeprecatedPersistentMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Gonna be replaced by PersistentMySegmentsStorage")
protocol OneKeyPersistentMySegmentsStorage {
    func set(_ segments: [String])
    func getSnapshot() -> [String]
}

@available(*, deprecated, message: "Gonna be replaced by DefaultPersistentMySegmentsStorage")
class DefaultOneKeyPersistentMySegmentsStorage: OneKeyPersistentMySegmentsStorage {

    private let mySegmentsDao: MySegmentsDao
    private let userKey: String

    init(userKey: String, database: SplitDatabase) {
        self.userKey = userKey
        self.mySegmentsDao = database.mySegmentsDao
    }

    func set(_ segments: [String]) {
        mySegmentsDao.update(userKey: userKey, segmentList: segments)
    }

    func getSnapshot() -> [String] {
        return mySegmentsDao.getBy(userKey: userKey)
    }
}

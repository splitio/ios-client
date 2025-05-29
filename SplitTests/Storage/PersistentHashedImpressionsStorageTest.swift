//
//  PersistentHashedImpressionsStorageTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class PersistentHashedImpressionsStorageTests: XCTestCase {
    var hashedStorage: PersistentHashedImpressionsStorage!
    var hashDao: HashedImpressionDaoMock!

    override func setUp() {
        hashDao = HashedImpressionDaoMock()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.hashedImpressionDao = hashDao
        hashedStorage = DefaultPersistentHashedImpressionsStorage(database: SplitDatabaseStub(daoProvider: daoProvider))
    }

    func testUpdate() {
        let all1 = hashDao.items
        hashedStorage.update(SplitTestHelper.createHashedImpressions(start: 10, count: 15))
        let all2 = hashDao.items

        XCTAssertEqual(0, all1.count)
        XCTAssertEqual(15, all2.count)
    }

    func testGetAll() {
        let count = 20
        hashDao.items = SplitTestHelper.createHashedImpressionsDic(start: 1, count: count)
        let all = hashedStorage.getAll()

        XCTAssertEqual(count, all.count)
    }
}

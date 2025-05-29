//
//  PersistentUniqueKeysStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17-May-2022
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PersistentUniqueKeysStorageTests: XCTestCase {
    var keysStorage: PersistentUniqueKeysStorage!
    var keyDao: UniqueKeyDaoStub!

    override func setUp() {
        keyDao = UniqueKeyDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.uniqueKeyDao = keyDao
        keysStorage = DefaultPersistentUniqueKeysStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider),
            expirationPeriod: 100)
    }

    func testPush() {
        keysStorage.pushMany(keys: createUniqueKeys())

        XCTAssertEqual(20, keyDao.insertedKeys.count)
    }

    func testPop() {
        keyDao.getByKeys = createUniqueKeys()
        let popped = keysStorage.pop(count: 100)

        XCTAssertEqual(keyDao.getByKeys.count, popped.count)
        XCTAssertEqual(keyDao.updatedStatus.count, popped.count)
        XCTAssertEqual(0, keyDao.updatedStatus.values.filter { $0 == StorageRecordStatus.active }.count)
    }

    func testDelete() {
        let keys = createUniqueKeys()
        keysStorage.delete(keys)

        XCTAssertEqual(keyDao.deletedKeys.count, keys.count)
    }

    func testSetActive() {
        let keys = createUniqueKeys()

        keysStorage.setActiveAndUpdateSendCount(keys.map { $0.storageId ?? "" })

        XCTAssertEqual(keys.count, keyDao.updatedStatus.values.filter { $0 == StorageRecordStatus.active }.count)
        XCTAssertEqual(0, keyDao.updatedStatus.values.filter { $0 == StorageRecordStatus.deleted }.count)
    }

    override func tearDown() {}

    func createUniqueKeys() -> [UniqueKey] {
        var keys = [UniqueKey]()
        for i in 0 ..< 20 {
            let key = UniqueKey(storageId: "id_\(i)", userKey: "key_\(i)", features: ["f_1_\(i)", "f_2_\(i)"])
            keys.append(key)
        }
        return keys
    }
}

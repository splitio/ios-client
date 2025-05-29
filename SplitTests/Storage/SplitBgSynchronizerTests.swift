//
//  SplitBgSynchronizerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24/11/2023.
//  Copyright © 2023 Split. All rights reserved.
//

@testable import Split
import XCTest

private typealias SyncItem = SplitBgSynchronizer.SyncItem
private typealias BgSyncSchedule = SplitBgSynchronizer.BgSyncSchedule

class SplitBgSynchronizerTest: XCTestCase {
    let bgSync = SplitBgSynchronizer.shared
    let storage = KeyValueStorageMock()

    override func setUp() {
        bgSync.globalStorage = storage
    }

    func testRegister() {
        register()

        let data = getSyncTaskMap()

        let d1 = data["dbKey1"]
        let d2 = data["dbKey2"]

        XCTAssertEqual(d1?.apiKey, "dbKey1")
        XCTAssertNil(d1?.prefix)
        XCTAssertEqual(d1?.encryptionLevel, SplitEncryptionLevel.none.rawValue)
        XCTAssertEqual(d1?.userKeys.keys.sorted(), ["key1", "key2"])

        XCTAssertEqual(d2?.apiKey, "dbKey2")
        XCTAssertEqual(d2?.prefix, "pref")
        XCTAssertEqual(d2?.encryptionLevel, SplitEncryptionLevel.aes128Cbc.rawValue)
        XCTAssertEqual(d2?.userKeys.keys.sorted(), ["key2"])
    }

    func testRegisterRemove() {
        register()
        bgSync.unregister(dbKey: "dbKey1", userKey: "key1")
        bgSync.unregister(dbKey: "dbKey2", userKey: "key2")
        let data = getSyncTaskMap()

        let d1 = data["dbKey1"]
        let d2 = data["dbKey2"]

        XCTAssertEqual(d1?.apiKey, "dbKey1")
        XCTAssertNil(d1?.prefix)
        XCTAssertEqual(d1?.encryptionLevel, SplitEncryptionLevel.none.rawValue)
        XCTAssertEqual(d1?.userKeys.keys.sorted(), ["key2"])

        XCTAssertNil(d2)
    }

    func testRemoveAll() {
        register()
        bgSync.unregisterAll()

        let data = getSyncTaskMap()

        XCTAssertEqual(data.count, 0)
    }

    private func register() {
        bgSync.register(
            dbKey: "dbKey1",
            prefix: nil,
            userKey: "key1",
            encryptionLevel: SplitEncryptionLevel.none)

        bgSync.register(
            dbKey: "dbKey1",
            prefix: nil,
            userKey: "key2",
            encryptionLevel: SplitEncryptionLevel.none)

        bgSync.register(
            dbKey: "dbKey2",
            prefix: "pref",
            userKey: "key2",
            encryptionLevel: SplitEncryptionLevel.aes128Cbc)
    }

    private func getSyncTaskMap() -> [String: SplitBgSynchronizer.SyncItem] {
        return storage.get(item: .backgroundSyncSchedule, type: BgSyncSchedule.self) ?? [String: SyncItem]()
    }
}

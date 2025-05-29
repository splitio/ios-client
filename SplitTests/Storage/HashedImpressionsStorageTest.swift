//
//  HashedImpressionsStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HashedImpressionsStorageTests: XCTestCase {
    var hashedStorage: HashedImpressionsStorage!
    var persistentStorage: PersistentHashedImpressionStorageMock!
    var lruCache: LRUCache<UInt32, Int64>!
    let count = 20

    override func setUp() {
        lruCache = LRUCache(capacity: 200)
        persistentStorage = PersistentHashedImpressionStorageMock()
        persistentStorage.items = SplitTestHelper.createHashedImpressionsDic(start: 1, count: count)
        // Adding expired
        persistentStorage.items[1000] = HashedImpression(impressionHash: 1000, time: 999, createdAt: 999)

        hashedStorage = DefaultHashedImpressionsStorage(
            cache: lruCache,
            persistentStorage: persistentStorage)
    }

    func testLoad() {
        let loadedBef = lruCache.all()
        hashedStorage.loadFromDb()

        let loadedAfter = lruCache.all()

        XCTAssertEqual(0, loadedBef.count)
        XCTAssertEqual(count, loadedAfter.count)
        XCTAssertNil(loadedAfter[1000])
    }

    func testLoadExpired() {
        persistentStorage.items[1000] = HashedImpression(impressionHash: 1000, time: 999, createdAt: 1)
        for item in SplitTestHelper.createHashedImpressionsDic(start: count - 4, count: 10, expired: true) {
            persistentStorage.items[item.key] = item.value
        }

        hashedStorage.loadFromDb()

        let loaded = lruCache.all()

        XCTAssertEqual(count - 5, loaded.count)
        XCTAssertNil(loaded[1000])
    }

    func testUpdateNoSave() {
        updateTest(save: false)
    }

    func testUpdateSave() {
        updateTest(save: true)
    }

    func testGet() {
        hashedStorage.loadFromDb()
        for i in 1 ..< count {
            XCTAssertNotNil(hashedStorage.get(for: UInt32(i)))
        }
    }

    func testSave() {
        let sum = 10
        hashedStorage.loadFromDb()
        let countBef = persistentStorage.items.count
        for i in SplitTestHelper.createHashedImpressions(start: 30, count: sum) {
            hashedStorage.set(i.time, for: i.impressionHash)
        }

        let countAfter = persistentStorage.items.count

        hashedStorage.save()
        let countAfterSave = persistentStorage.items.count
        XCTAssertEqual(count, countBef)
        XCTAssertEqual(count, countAfter)
        XCTAssertEqual(count + sum, countAfterSave)
    }

    func testSaveOnQueue() {
        hashedStorage.loadFromDb()
        let countBef = persistentStorage.items.count
        for i in SplitTestHelper.createHashedImpressions(
            start: 30,
            count: ServiceConstants.maxHashedImpressionsQueueSize - 1) {
            hashedStorage.set(i.time, for: i.impressionHash)
        }

        let i = SplitTestHelper.createHashedImpressions(
            start: 100,
            count: ServiceConstants.maxHashedImpressionsQueueSize - 1)[0]
        hashedStorage.set(i.time, for: i.impressionHash)

        let countAfter = persistentStorage.items.count

        XCTAssertEqual(count, countBef)
        XCTAssertEqual(count + ServiceConstants.maxHashedImpressionsQueueSize, countAfter)
    }

    private func updateTest(save: Bool) {
        hashedStorage.loadFromDb()

        let cacheAllBef = lruCache.all()
        let allBef = persistentStorage.items
        let itemBef = hashedStorage.get(for: 31)

        let itemInCacheBef = hashedStorage.get(for: 1)
        hashedStorage.set(100, for: 31)

        if save {
            hashedStorage.save()
        }

        let itemAfter = hashedStorage.get(for: 31)
        let itemCacheAfter = hashedStorage.get(for: 31)

        let allAfter = persistentStorage.items
        let cacheAfter = lruCache.all()

        XCTAssertNil(itemBef)
        XCTAssertEqual(20, allBef.count)
        XCTAssertEqual(20, cacheAllBef.count)
        XCTAssertNotNil(itemInCacheBef)

        XCTAssertEqual(100, itemAfter)
        XCTAssertEqual(Int64(100), cacheAfter[31])
        XCTAssertEqual(100, itemCacheAfter)

        if save {
            XCTAssertEqual(21, allAfter.count)
            XCTAssertNotNil(allAfter[1])
        } else {
            XCTAssertEqual(20, allAfter.count)
            XCTAssertNil(allAfter[31])
        }
    }
}

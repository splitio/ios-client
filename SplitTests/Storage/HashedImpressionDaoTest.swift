//
//  HashedImpressionDaoTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20-05-2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HashedImpressionDaoTest: XCTestCase {
    var dao: HashedImpressionDao!

    override func setUp() {
        let queue = DispatchQueue(label: "hashed impression dao test")
        dao = CoreDataHashedImpressionDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
    }

    func testUpdate() {
        dao.update(SplitTestHelper.createHashedImpressions(start: 1, count: 10))
        let all1 = dao.getAll().sorted(by: { $0.impressionHash < $1.impressionHash })
        dao.update(SplitTestHelper.createHashedImpressions(start: 11, count: 15))
        let all2 = dao.getAll().sorted(by: { $0.impressionHash < $1.impressionHash })

        dao.update([HashedImpression(impressionHash: 11, time: 11, createdAt: 123456)])
        dao.update([HashedImpression(impressionHash: 12, time: 12, createdAt: 123456)])

        XCTAssertEqual(10, all1.count)
        XCTAssertEqual(25, all2.count)

        XCTAssertNotNil(getImp(all1, hash: 1))
        XCTAssertNotNil(getImp(all1, hash: 10))

        XCTAssertNil(getImp(all1, hash: 11))

        XCTAssertNotNil(getImp(all2, hash: 11))
        XCTAssertNotNil(getImp(all2, hash: 25))
    }

    func testGetAll() {
        dao.update(SplitTestHelper.createHashedImpressions(start: 1, count: 10))

        let all1 = dao.getAll()

        dao.update(SplitTestHelper.createHashedImpressions(start: 11, count: 20))

        let all2 = dao.getAll()

        dao.update(SplitTestHelper.createHashedImpressions(start: 21, count: 30))

        let all3 = dao.getAll()

        XCTAssertEqual(10, all1.count)
        XCTAssertEqual(30, all2.count)
        XCTAssertEqual(50, all3.count)
    }

    func testDelete() {
        let count = 10
        dao.update(SplitTestHelper.createHashedImpressions(start: 0, count: count))

        let allBef = dao.getAll()
        let countBef = allBef.count

        dao.delete(allBef.filter { $0.impressionHash < 5 })

        let allAfter = dao.getAll()
        let countAfter = allAfter.count

        XCTAssertEqual(countBef, count)
        XCTAssertEqual(countAfter, 5)
        XCTAssertEqual(0, allAfter.filter { $0.impressionHash == 1 }.count)
        XCTAssertEqual(1, allAfter.filter { $0.impressionHash == 6 }.count)
    }

    private func getImp(_ items: [HashedImpression], hash: UInt32) -> HashedImpression? {
        let res = items.filter { $0.impressionHash == hash }
        if !res.isEmpty {
            return res[0]
        }
        return nil
    }
}

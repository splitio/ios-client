//
//  HashedImpressionDaoTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20-05-2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HashedImpressionDaoTest: XCTestCase {

    var dao: HashedImpressionDao!

    override func setUp() {
        let queue = DispatchQueue(label: "hashed impression dao test")
        dao = CoreDataHashedImpressionDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        dao.set(SplitTestHelper.createHashedImpressions())
    }

    func testSet() {
        let all1 = dao.getAll().sorted(by: { $0.impressionHash < $1.impressionHash })
        dao.set(SplitTestHelper.createHashedImpressions(start: 11, count: 15))
        let all2 = dao.getAll().sorted(by: { $0.impressionHash < $1.impressionHash })

        XCTAssertEqual(10, all1.count)
        XCTAssertEqual(15, all2.count)

        XCTAssertEqual(1, all1[0].impressionHash)
        XCTAssertEqual(10, all1[9].impressionHash)

        XCTAssertEqual(11, all2[0].impressionHash)
        XCTAssertEqual(25, all2[14].impressionHash)
    }
}

//
//  GeneralInfoDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class GeneralInfoDaoTest: XCTestCase {
    var generalInfoDao: GeneralInfoDao!

    override func setUp() {
        let queue = DispatchQueue(label: "general info dao test")
        generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
    }

    func testGetNilStringValue() {
        let v = generalInfoDao.stringValue(info: .splitsFilterQueryString)

        XCTAssertNil(v)
    }

    func testGetNilLongValue() {
        let v = generalInfoDao.longValue(info: .splitsChangeNumber)

        XCTAssertNil(v)
    }

    func testCreateUpdateGetStringValue() {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "q=1")
        let v1 = generalInfoDao.stringValue(info: .splitsFilterQueryString)

        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "q=2")
        let v2 = generalInfoDao.stringValue(info: .splitsFilterQueryString)

        XCTAssertEqual("q=1", v1)
        XCTAssertEqual("q=2", v2)
    }

    func testCreateUpdateGetLongValue() {
        generalInfoDao.update(info: .splitsChangeNumber, longValue: 1)
        let v1 = generalInfoDao.longValue(info: .splitsChangeNumber)

        generalInfoDao.update(info: .splitsChangeNumber, longValue: 2)
        let v2 = generalInfoDao.longValue(info: .splitsChangeNumber)

        XCTAssertEqual(1, v1)
        XCTAssertEqual(2, v2)
    }

    override func tearDown() {}
}

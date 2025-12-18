//
//  GeneralInfoDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class GeneralInfoDaoTest: XCTestCase {
    
    var generalInfoDao: GeneralInfoDao!
    
    override func setUp() {
        let queue = DispatchQueue(label: "general info dao test")
        generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
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
    
    func testCreateUpdateSegmentsInUse() {
        let data: Int64 = 13
        
        generalInfoDao.update(info: .segmentsInUse, longValue: data)
        let segmentsInUse = generalInfoDao.longValue(info: .segmentsInUse)
        
        XCTAssertEqual(data, segmentsInUse)
    }
    
    func testTransactionalUpdateDoesNotSaveUntilCallerSaves() {
        guard let coreDataDao = generalInfoDao as? CoreDataGeneralInfoDao else {
            XCTFail("Expected CoreDataGeneralInfoDao")
            return
        }
        
        coreDataDao.coreDataHelper.performAndWait {
            coreDataDao.transactionalUpdate(info: .splitsChangeNumber, longValue: 999)
        }
        
        // Value should be in context but we need to save to persist
        coreDataDao.coreDataHelper.save()
        
        let savedValue = generalInfoDao.longValue(info: .splitsChangeNumber)
        XCTAssertEqual(999, savedValue)
    }
    
    func testTransactionalUpdateUpdatesExistingValue() {
        guard let coreDataDao = generalInfoDao as? CoreDataGeneralInfoDao else {
            XCTFail("Expected CoreDataGeneralInfoDao")
            return
        }
        
        // Create initial value
        generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 100)
        
        // Wait for async save to complete
        let exp = expectation(description: "wait for save")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        
        // Transactionally update
        coreDataDao.coreDataHelper.performAndWait {
            coreDataDao.transactionalUpdate(info: .splitsUpdateTimestamp, longValue: 200)
        }
        coreDataDao.coreDataHelper.save()
        
        let updatedValue = generalInfoDao.longValue(info: .splitsUpdateTimestamp)
        XCTAssertEqual(200, updatedValue)
    }

    override func tearDown() {
    }
}




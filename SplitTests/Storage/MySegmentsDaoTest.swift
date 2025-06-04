//
//  MySegmentsDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsDaoTest: XCTestCase {
    
    var mySegmentsDao: MySegmentsDao!
    var mySegmentsDaoAes128Cbc: MySegmentsDao!
    
    override func setUp() {
        let queue = DispatchQueue(label: "my segments dao test")
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
                                              entity: .mySegment)
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
                                                       entity: .mySegment,
                                                       cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
    }
    
    func testUpdateGetPlainText() {
        updateGet(dao: mySegmentsDao)
    }

    func testUpdateGetAes128Cbc() {
        updateGet(dao: mySegmentsDaoAes128Cbc)
    }

    func updateGet(dao: MySegmentsDao) {
        let userKey = "ukey"
        let change = SegmentChange(segments: ["s1", "s2"])
        dao.update(userKey: userKey, change: change)

        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(2, mySegments?.segments.count)
        XCTAssertEqual(1, mySegments?.segments.compactMap { $0.name } .filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments?.segments.compactMap { $0.name } .filter { $0 == "s2" }.count)
    }

    func testGetInvalidKeyPlainText() {
        getInvalidKey(dao: mySegmentsDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        getInvalidKey(dao: mySegmentsDaoAes128Cbc)
    }

    func getInvalidKey(dao: MySegmentsDao) {
        let userKey = "ukey"
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertNil(mySegments?.segments.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                               dispatchQueue: DispatchQueue(label: "impression dao test"))
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: helper,
                                              entity: .myLargeSegment)
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: helper,
                                                       entity: .mySegment,
                                                       cipher: cipher)

        // create segment and get one encrypted feature name
        let userKey = "ukey"
        let userKeyEnc = cipher.encrypt(userKey) ?? "fail"

        // Create encrypted my segment
        let change = SegmentChange(segments: ["s1", "s2"])
        mySegmentsDaoAes128Cbc.update(userKey: userKey, change: change)

        // load segment and filter them by encrypted key
        let segment = getBy(userKey: userKeyEnc, coreDataHelper: helper)

        XCTAssertNotEqual(userKey, segment.userKey)
        XCTAssertFalse(segment.segmentList?.contains("s1") ?? true)
    }

    func testDeleteAll() {
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                               dispatchQueue: DispatchQueue(label: "impression dao test"))
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: helper,
                                              entity: .mySegment)
        let userKey = "ukey"
        let change = SegmentChange(segments: ["s1", "s2"])
        mySegmentsDao.update(userKey: userKey, change: change)

        let initialResultFromDB = mySegmentsDao.getBy(userKey: userKey)

        mySegmentsDao.deleteAll()

        let finalResultFromDB = mySegmentsDao.getBy(userKey: userKey)

        XCTAssertEqual(2, initialResultFromDB?.segments.count)
        XCTAssertNil(finalResultFromDB)
    }

    func getBy(userKey: String, coreDataHelper: CoreDataHelper) -> (userKey: String?, segmentList: String?) {
        var loadedUserKey: String? = nil
        var segmentList: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "userKey == %@", userKey)
            let entities = coreDataHelper.fetch(entity: .mySegment,
                                                where: predicate,
                                                rowLimit: 1).compactMap { return $0 as? MySegmentEntity }
            if entities.count > 0 {
                loadedUserKey = entities[0].userKey
                segmentList = entities[0].segmentList
            }
        }
        return (userKey: loadedUserKey, segmentList: segmentList)
    }
}


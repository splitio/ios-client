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
    var queue: DispatchQueue!

    override func setUp() {
        queue = DispatchQueue(label: "my segments dao test")
    }

    func initDao(entity: CoreDataEntity) {
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                            dispatchQueue: queue),
                                              coreDataEntity: entity)
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                                     dispatchQueue: queue),
                                                       coreDataEntity: entity,
                                                       cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
    }


    func testUpdateGetPlainText() {
        initDao(entity: .mySegment)
        updateGet(dao: mySegmentsDao)

        initDao(entity: .myLargeSegment)
        updateGet(dao: mySegmentsDao)

    }

    func testUpdateGetAes128Cbc() {
        initDao(entity: .mySegment)
        updateGet(dao: mySegmentsDaoAes128Cbc)
        
        initDao(entity: .myLargeSegment)
        updateGet(dao: mySegmentsDaoAes128Cbc)
    }

    func updateGet(dao: MySegmentsDao) {
        let userKey = "ukey"
        dao.update(userKey: userKey, segmentList: ["s1", "s2"])
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(2, mySegments.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s2" }.count)
    }

    func testGetInvalidKeyPlainText() {
        initDao(entity: .mySegment)
        getInvalidKey(dao: mySegmentsDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        initDao(entity: .mySegment)
        getInvalidKey(dao: mySegmentsDaoAes128Cbc)
    }

    func getInvalidKey(dao: MySegmentsDao) {
        let userKey = "ukey"
        
        let mySegments = dao.getBy(userKey: userKey)
        
        XCTAssertEqual(0, mySegments.count)
    }

    func testDataIsEncryptedInDb() {
        initDao(entity: .mySegment)
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                               dispatchQueue: DispatchQueue(label: "impression dao test"))
        mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: helper, coreDataEntity: .mySegment)
        mySegmentsDaoAes128Cbc = CoreDataMySegmentsDao(coreDataHelper: helper,
                                                       coreDataEntity: .mySegment,
                                                       cipher: cipher)

        // create segment and get one encrypted feature name
        let userKey = "ukey"
        let userKeyEnc = cipher.encrypt(userKey) ?? "fail"

        // Create encrypted my segment
        mySegmentsDaoAes128Cbc.update(userKey: userKey, segmentList: ["s1", "s2"])

        // load segment and filter them by encrypted key
        let segment = getBy(userKey: userKeyEnc, coreDataHelper: helper)

        XCTAssertNotEqual(userKey, segment.userKey)
        XCTAssertFalse(segment.segmentList?.contains("s1") ?? true)
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


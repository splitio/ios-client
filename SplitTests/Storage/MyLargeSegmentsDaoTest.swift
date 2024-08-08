//
//  MyLargeSegmentsDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MyLargeSegmentDaoTest: XCTestCase {

    var myLargeSegmentsDao: MyLargeSegmentsDao!
    var myLargeSegmentsDaoAes128Cbc: MyLargeSegmentsDao!

    override func setUp() {
        let queue = DispatchQueue(label: "my large segments dao test")
        myLargeSegmentsDao = CoreDataMyLargeSegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                                      dispatchQueue: queue))
        myLargeSegmentsDaoAes128Cbc = CoreDataMyLargeSegmentsDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                                               dispatchQueue: queue),
                                                                 cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
    }
    
    func testUpdateGetPlainText() {
        updateGet(dao: myLargeSegmentsDao)
    }

    func testUpdateGetAes128Cbc() {
        updateGet(dao: myLargeSegmentsDaoAes128Cbc)
    }

    func updateGet(dao: MyLargeSegmentsDao) {
        let userKey = "ukey"
        let change = SegmentChange(segments: ["s1", "s2"], changeNumber: 100)
        dao.update(userKey: userKey, change: change)

        let mySegments = dao.getBy(userKey: userKey)?.segments ?? []
        let changeNumber = dao.getBy(userKey: userKey)?.changeNumber ?? -1

        XCTAssertEqual(100, changeNumber)
        XCTAssertEqual(2, mySegments.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, mySegments.filter { $0 == "s2" }.count)
    }

    func testGetInvalidKeyPlainText() {
        getInvalidKey(dao: myLargeSegmentsDao)
    }

    func testGetInvalidKeyAes128Cbc() {
        getInvalidKey(dao: myLargeSegmentsDaoAes128Cbc)
    }

    func getInvalidKey(dao: MyLargeSegmentsDao) {
        let userKey = "ukey"
        
        let mySegments = dao.getBy(userKey: userKey)?.segments ?? []
        let changeNumber = dao.getBy(userKey: userKey)?.changeNumber ?? -100

        XCTAssertEqual(0, mySegments.count)
        XCTAssertEqual(-100, changeNumber)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                               dispatchQueue: DispatchQueue(label: "my large segments dao test"))
        myLargeSegmentsDao = CoreDataMyLargeSegmentsDao(coreDataHelper: helper)
        myLargeSegmentsDaoAes128Cbc = CoreDataMyLargeSegmentsDao(coreDataHelper: helper,
                                                       cipher: cipher)

        // create segment and get one encrypted feature name
        let userKey = "ukey"
        let userKeyEnc = cipher.encrypt(userKey) ?? "fail"

        // Create encrypted my segment
        let change = SegmentChange(segments: ["s1", "s2"], changeNumber: 100)
        myLargeSegmentsDaoAes128Cbc.update(userKey: userKey, change: change)

        // load segment and filter them by encrypted key
        let segment = getBy(userKey: userKeyEnc, coreDataHelper: helper)

        XCTAssertNotEqual(userKey, segment.userKey)
        XCTAssertFalse(segment.body?.contains("s1") ?? true)
        XCTAssertFalse(segment.body?.contains("100") ?? true)
}

    func getBy(userKey: String, coreDataHelper: CoreDataHelper) -> (userKey: String?, body: String?) {
        var loadedUserKey: String? = nil
        var body: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "userKey == %@", userKey)
            let entities = coreDataHelper.fetch(entity: .myLargeSegment,
                                                where: predicate,
                                                rowLimit: 1).compactMap { return $0 as? MyLargeSegmentEntity }
            if entities.count > 0 {
                loadedUserKey = entities[0].userKey
                body = entities[0].body
            }
        }
        return (userKey: loadedUserKey, body: body)
    }
}

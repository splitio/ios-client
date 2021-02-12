//
//  StorageMigratorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class StorageMigratorTests: XCTestCase {

    var fileStorage: FileStorageStub!
    var splitDatabase: SplitDatabase!
    var migrator: StorageMigrator!
    let userKey = IntegrationHelper.dummyUserKey
    let kImpressionsFileName: String = "SPLITIO.impressions"
    let kEventsFileName: String = "SPLITIO.events_track"
    let kSplitsFileName: String = "SPLITIO.splits"
    var mySegmentsFileName: String!


    override func setUp() {
        splitDatabase = TestingHelper.createTestDatabase(name: "storage_migrator_test")
        fileStorage = FileStorageStub()
        migrator = DefaultStorageMigrator(fileStorage: fileStorage, splitDatabase: splitDatabase, userKey: userKey)
        mySegmentsFileName = "SPLITIO.mySegments_\(userKey)"
    }

    func testSuccessfulMigration() {

        let eventsContent = TestingHelper.createLegacyEventsFileContent(count: 10)
        let impressionsContent = TestingHelper.createLegacyImpressionsFileContent(testCount: 10, impressionsPerTest: 10)

        fileStorage.write(fileName: kImpressionsFileName, content: impressionsContent)
        fileStorage.write(fileName: kEventsFileName, content: eventsContent)

        let wasRun = migrator.runMigrationIfNeeded()

        let events = splitDatabase.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)
        let impressions = splitDatabase.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)


        XCTAssertTrue(wasRun)
        XCTAssertEqual(100, events.count)
        XCTAssertEqual(100, impressions.count)
        XCTAssertNil(fileStorage.read(fileName: kImpressionsFileName))
        XCTAssertNil(fileStorage.read(fileName: kEventsFileName))
        XCTAssertNil(fileStorage.read(fileName: kSplitsFileName))
        XCTAssertNil(fileStorage.read(fileName: mySegmentsFileName))
    }

    func testEmptyMigration() {

        let wasRun = migrator.runMigrationIfNeeded()

        let events = splitDatabase.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)
        let impressions = splitDatabase.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)

        XCTAssertFalse(wasRun)
        XCTAssertEqual(0, events.count)
        XCTAssertEqual(0, impressions.count)
        XCTAssertNil(fileStorage.read(fileName: kImpressionsFileName))
        XCTAssertNil(fileStorage.read(fileName: kEventsFileName))
        XCTAssertNil(fileStorage.read(fileName: kSplitsFileName))
        XCTAssertNil(fileStorage.read(fileName: mySegmentsFileName))
    }

    func testOudatedFilesMigration() {
        let eventsContent = TestingHelper.createLegacyEventsFileContent(count: 10)
        let impressionsContent = TestingHelper.createLegacyImpressionsFileContent(testCount: 10, impressionsPerTest: 10)

        fileStorage.write(fileName: kImpressionsFileName, content: impressionsContent)
        fileStorage.write(fileName: kEventsFileName, content: eventsContent)

        fileStorage.lastModified[kImpressionsFileName] = 100
        fileStorage.lastModified[kEventsFileName] = 100
        let wasRun = migrator.runMigrationIfNeeded()

        let events = splitDatabase.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)
        let impressions = splitDatabase.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)

        XCTAssertFalse(wasRun)
        XCTAssertEqual(0, events.count)
        XCTAssertEqual(0, impressions.count)
        XCTAssertNil(fileStorage.read(fileName: kImpressionsFileName))
        XCTAssertNil(fileStorage.read(fileName: kEventsFileName))
        XCTAssertNil(fileStorage.read(fileName: kSplitsFileName))
        XCTAssertNil(fileStorage.read(fileName: mySegmentsFileName))
    }

    func testErrorOnMigration() {
        // On error set migration as done
        fileStorage.write(fileName: kImpressionsFileName, content: "wrong content")
        fileStorage.write(fileName: kEventsFileName, content: "wrong content")
        let wasRun = migrator.runMigrationIfNeeded()
        let wasRunAfterError = migrator.runMigrationIfNeeded()

        let events = splitDatabase.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)
        let impressions = splitDatabase.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1000)

        XCTAssertTrue(wasRun)
        XCTAssertFalse(wasRunAfterError)
        XCTAssertEqual(0, events.count)
        XCTAssertEqual(0, impressions.count)
        XCTAssertNil(fileStorage.read(fileName: kImpressionsFileName))
        XCTAssertNil(fileStorage.read(fileName: kEventsFileName))
        XCTAssertNil(fileStorage.read(fileName: kSplitsFileName))
        XCTAssertNil(fileStorage.read(fileName: mySegmentsFileName))
    }

    override func tearDown() {
    }

    
}


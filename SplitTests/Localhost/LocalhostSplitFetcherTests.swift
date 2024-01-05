//
//  LocalhostSplitFetcherTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/02/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class LocalhostSplitFetcherTests: XCTestCase {

    var storage: FileStorageProtocol!
    var eventsManager: SplitEventsManagerMock!

    override func setUp() {
    }

    override func tearDown() {
    }

    func testInitial() {
        let fileName =  "localhost.splits"
        let splitsStorage = splitsStorageFor(fileName: fileName)
        XCTAssertEqual(splitsStorage.getAll().count, 5)
        for i in 1...5 {
            XCTAssertEqual(splitsStorage.get(name: "s\(i)")?.name, "s\(i)")
        }
        let events: SplitEventsManagerMock = eventsManager
        XCTAssertTrue(events.isSdkReadyFired)
    }
    
    func testFileUpdate() {
        let fileName =  "localhost.splits"
        let splitsStorage = splitsStorageFor(fileName: fileName)

        wait(for: [eventsManager.readyExp!], timeout: 5)
        let fileContent = """
                            s5 t5\n
                            s6 t6\n
                            s7 t7
                            """
        storage.write(fileName: fileName, content: fileContent)
        splitsStorage.loadLocal()
        XCTAssertEqual(splitsStorage.getAll().count, 3)
        for i in 5...7 {
            XCTAssertEqual(splitsStorage.get(name: "s\(i)")?.name, "s\(i)")
        }

        XCTAssertTrue(eventsManager.isSdkReadyFired)
    }
    
    func testFileUpdate2() {
        let fileName =  "localhost.splits"
        let splitsStorage = splitsStorageFor(fileName: fileName)
        wait(for: [eventsManager.readyExp!], timeout: 5)
        let fileContent = """
                            s5 t5\n
                            s6 t6\n
                            s7 t7\n
                            s8 t8
                            """
        storage.write(fileName: fileName, content: fileContent)
        splitsStorage.loadLocal()
        XCTAssertEqual(splitsStorage.getAll().count, 4)
        for i in 5...8 {
            XCTAssertEqual(splitsStorage.get(name: "s\(i)")?.name, "s\(i)")
        }
        XCTAssertTrue(eventsManager.isSdkReadyFired)
    }
    
    func testWrongLegacyFormatUpdate() {
        let fileName =  "localhost.splits"
        let splitsStorage = splitsStorageFor(fileName: fileName)
        wait(for: [eventsManager.readyExp!], timeout: 5)
        let originalCount = splitsStorage.getAll().count
        let fileContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        splitsStorage.loadLocal()
        
        XCTAssertEqual(5, originalCount)
        XCTAssertEqual(splitsStorage.getAll().count, 0)
    }
    
    func testWrongYamlFormatUpdate() {
        let fileName =  "localhost.yaml"
        let splitsStorage = splitsStorageFor(fileName: fileName)
        wait(for: [eventsManager.readyExp!], timeout: 5)
        let originalCount = splitsStorage.getAll().count
        let fileContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        splitsStorage.loadLocal()
        
        XCTAssertEqual(9, originalCount)
        XCTAssertEqual(splitsStorage.getAll().count, 0)
    }
    
    func testInvalidTypeFile() {
        let _ = splitsStorageFor(fileName: "splits.txt")
        let events: SplitEventsManagerMock = eventsManager
        wait(for: [eventsManager.timeoutExp!], timeout: 5)
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func testNonExistingFile() {
        let _ = splitsStorageFor(fileName: "non_existing_splits.yaml")
        let events: SplitEventsManagerMock = eventsManager
        wait(for: [eventsManager.timeoutExp!], timeout: 5)
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func testWrongFormatYml() {
        let _ = splitsStorageFor(fileName: "wrong_format.yaml")
        let events: SplitEventsManagerMock = eventsManager
        wait(for: [eventsManager.timeoutExp!], timeout: 5)
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func splitsStorageFor(fileName: String) -> SplitsStorage {
        eventsManager = SplitEventsManagerMock()
        eventsManager.readyExp = XCTestExpectation()
        eventsManager.timeoutExp = XCTestExpectation()

        storage = FileStorageStub()
        var config = FeatureFlagsFileLoaderConfig()
        config.refreshInterval = 0
//        return LocalhostSplitsStorage(fileStorage: storage, config: config,
//                                 eventsManager: eventsManager, dataFolderName: "localhost", splitsFileName: fileName,
//                                                      bundle: Bundle(for: type(of: self)))

                return LocalhostSplitsStorage()

    }

}

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
    var fetcher: SplitFetcher!
    var eventsManager: SplitEventsManager!

    override func setUp() {
    }

    override func tearDown() {
    }

    func testInitial() {
        let fileName =  "localhost.splits"
        fetcherFor(fileName: fileName)
        XCTAssertEqual(fetcher.fetchAll()?.count, 5)
        for i in 1...5 {
            XCTAssertEqual(fetcher.fetch(splitName: "s\(i)")?.name, "s\(i)")
        }
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertTrue(events.isSdkReadyFired)
    }
    
    func testFileUpdate() {
        let fileName =  "localhost.splits"
        fetcherFor(fileName: fileName)
        let fileContent = """
                            s5 t5\n
                            s6 t6\n
                            s7 t7
                            """
        storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        XCTAssertEqual(fetcher.fetchAll()?.count, 3)
        for i in 5...7 {
            XCTAssertEqual(fetcher.fetch(splitName: "s\(i)")?.name, "s\(i)")
        }
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertTrue(events.isSdkReadyFired)
    }
    
    func testFileUpdate2() {
        let fileName =  "localhost.splits"
        fetcherFor(fileName: fileName)
        let fileContent = """
                            s5 t5\n
                            s6 t6\n
                            s7 t7\n
                            s8 t8
                            """
        storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        XCTAssertEqual(fetcher.fetchAll()?.count, 4)
        for i in 5...8 {
            XCTAssertEqual(fetcher.fetch(splitName: "s\(i)")?.name, "s\(i)")
        }
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertTrue(events.isSdkReadyFired)
    }
    
    func testWrongLegacyFormatUpdate() {
        let fileName =  "localhost.splits"
        fetcherFor(fileName: fileName)
        let originalCount = fetcher.fetchAll()?.count
        let fileContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        
        XCTAssertEqual(5, originalCount)
        XCTAssertEqual(fetcher.fetchAll()?.count, 0)
    }
    
    func testWrongYamlFormatUpdate() {
        let fileName =  "localhost.yaml"
        fetcherFor(fileName: fileName)
        let originalCount = fetcher.fetchAll()?.count
        let fileContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        
        XCTAssertEqual(9, originalCount)
        XCTAssertEqual(fetcher.fetchAll()?.count, 0)
    }
    
    func testInvalidTypeFile() {
        fetcherFor(fileName: "splits.txt")
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func testNonExistingFile() {
        fetcherFor(fileName: "non_existing_splits.yaml")
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func testWrongFormatYml() {
        fetcherFor(fileName: "wrong_format.yaml")
        let events: SplitEventsManagerMock = eventsManager as! SplitEventsManagerMock
        XCTAssertFalse(events.isSdkReadyFired)
        XCTAssertTrue(events.isSdkTimeoutFired)
    }
    
    func fetcherFor(fileName: String) {
        let splitCache: SplitCacheProtocol = InMemorySplitCache(trafficTypesCache: InMemoryTrafficTypesCache())
        eventsManager = SplitEventsManagerMock()
        storage = FileStorageStub()
        var config = LocalhostSplitFetcherConfig()
        config.refreshInterval = 0
        fetcher = LocalhostSplitFetcher(fileStorage: storage, splitCache: splitCache, config: config, eventsManager: eventsManager, splitsFileName: fileName, bundle: Bundle(for: type(of: self)))
    }

}

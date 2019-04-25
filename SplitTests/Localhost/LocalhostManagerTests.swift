//
//  LocalhostTreatmentFetcherTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/02/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class LocalhostManagerTests: XCTestCase {

    var manager: SplitManager!
    var eventsManager: SplitEventsManager!
    let fileName = "localhost.splits"

    override func setUp() {
        eventsManager = SplitEventsManagerMock()
        /*let fileContent = """
                            s1 t1\n
                            s2 t2\n
                            s3 t3\n
                            s4 t4\n
                            s5 t5
                            """*/
        let storage: FileStorageProtocol = FileStorageStub()
        var config = LocalhostSplitFetcherConfig()
        config.refreshInterval = 0
        let fetcher: SplitFetcher = LocalhostSplitFetcher(fileStorage: storage, config: config, eventsManager: eventsManager, splitsFileName: fileName, bundle: Bundle(for: type(of: self)))
        //storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        manager = DefaultSplitManager(splitFetcher: fetcher)
    }

    override func tearDown() {
    }

    func testSplitNames() {
        
        let names = manager.splitNames
        XCTAssertEqual(names.count, 5)
        for i in 1...5 {
            XCTAssertNotEqual(indexForName(value: "s\(i)" , array: names), -1)
        }
    }
    
    func testSplits() {
        let names = manager.splits
        XCTAssertEqual(names.count, 5)
        for i in 1...5 {
            XCTAssertNotEqual(indexForSplit(name: "s\(i)" , array: names), -1)
        }
    }
    
    func testSplitsByName() {
        for i in 1...5 {
            XCTAssertNotNil(manager.split(featureName: "s\(i)"))
        }
        
        for i in 10...15 {
            XCTAssertNil(manager.split(featureName: "s\(i)"))
        }
    }
    
    private func indexForName(value: String, array: [String]?) -> Int {
        guard let array = array else {
            return -1
        }
        for (index, element) in array.enumerated() {
            if element == value {
                return index
            }
        }
        return -1
    }
    private func indexForSplit(name: String, array: [SplitView]?) -> Int {
        guard let array = array else {
            return -1
        }
        for (index, element) in array.enumerated() {
            if element.name == name {
                return index
            }
        }
        return -1
    }

}

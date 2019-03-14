//
//  LocalhostSplitClientTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split


class LocalhostSplitClientTests: XCTestCase {

    var client: SplitClient!
    
    override func setUp() {
        let fileName = "localhost.splits"
        let fileContent = """
                            s1 t1\n
                            s2 t2\n
                            s3 t3\n
                            s4 t4\n
                            s5 t5\n
                            """
        let storage = FileStorageStub()
        var config = LocalhostSplitFetcherConfig()
        config.refreshInterval = 0
        let fetcher = LocalhostTreatmentFetcher(fileStorage: storage, config: config)
        storage.write(fileName: fileName, content: fileContent)
        fetcher.forceRefresh()
        client = LocalhostSplitClient(treatmentFetcher: fetcher)
    }
    
    override func tearDown() {
    }
    
    func testRightTreatment() {
        for i in 1...5 {
            XCTAssertEqual(client.getTreatment("s\(i)"), "t\(i)")
        }
    }
    
    func testRightTreatments() {
        let splitsCount = 5
        var splits = [String]()
        for i in 1...splitsCount {
            splits.append("s\(i)")
        }
        let treatments = client.getTreatments(splits: splits, attributes: nil)
        for i in 1...splitsCount {
            XCTAssertEqual(treatments["s\(i)"], "t\(i)")
        }
    }
    
    func testNonExistingSplitsTreatment() {
        for i in 1...5 {
            XCTAssertEqual(client.getTreatment("j\(i)"), SplitConstants.CONTROL)
        }
    }
    
    func testNonExistingSplitsTreatments() {
        let splitsCount = 5
        var splits = [String]()
        for i in 1...splitsCount {
            splits.append("s\(i + 1000)")
        }
        let treatments = client.getTreatments(splits: splits, attributes: nil)
        for i in 1...splitsCount {
            XCTAssertEqual(treatments["s\(i + 1000)"], SplitConstants.CONTROL)
        }
    }

}

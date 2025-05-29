//
//  LocalhostSplitClientTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostSplitClientTests: XCTestCase {
    var client: SplitClient!
    var eventsManager: SplitEventsManager!
    let fileName = "localhost"
    let fileType = "splits"

    override func setUp() {
        let fileContent = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: fileType)!
        let content = LocalhostParserProvider.parser(for: .splits).parseContent(fileContent)
        let splitsStorage = LocalhostSplitsStorage()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: content!.values.map { $0 as Split },
            archivedSplits: [],
            changeNumber: 1,
            updateTimestamp: 1))

        client = LocalhostSplitClient(
            key: Key(matchingKey: "thekey"),
            splitsStorage: splitsStorage,
            clientManager: ClientManagerMock(),
            eventsManager: eventsManager,
            evaluator: DefaultEvaluator(
                splitsStorage: splitsStorage,
                mySegmentsStorage: EmptyMySegmentsStorage(),
                myLargeSegmentsStorage: EmptyMySegmentsStorage()))
    }

    override func tearDown() {}

    func testRightSplitsFileTreatment() {
        for i in 1 ... 5 {
            XCTAssertEqual(client.getTreatment("s\(i)"), "t\(i)")
        }
    }

    func testRightSplitsFileTreatments() {
        let splitsCount = 5
        var splits = [String]()
        for i in 1 ... splitsCount {
            splits.append("s\(i)")
        }
        let treatments = client.getTreatments(splits: splits, attributes: nil)
        for i in 1 ... splitsCount {
            XCTAssertEqual(treatments["s\(i)"], "t\(i)")
        }
    }

    func testNonExistingSplitsTreatment() {
        for i in 1 ... 5 {
            XCTAssertEqual(client.getTreatment("j\(i)"), SplitConstants.control)
        }
    }

    func testNonExistingSplitsTreatments() {
        let splitsCount = 5
        var splits = [String]()
        for i in 1 ... splitsCount {
            splits.append("s\(i + 1000)")
        }
        let treatments = client.getTreatments(splits: splits, attributes: nil)
        for i in 1 ... splitsCount {
            XCTAssertEqual(treatments["s\(i + 1000)"], SplitConstants.control)
        }
    }
}

//
//  LocalhostTreatmentFetcherTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/02/2018.
//  Copyright © 2018 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostManagerTests: XCTestCase {
    var manager: SplitManager!
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
        splitsStorage.loadLocal()
        manager = DefaultSplitManager(splitsStorage: splitsStorage)
    }

    override func tearDown() {}

    func testSplitNames() {
        let names = manager.splitNames
        XCTAssertEqual(names.count, 5)
        for i in 1 ... 5 {
            XCTAssertNotEqual(indexForName(value: "s\(i)", array: names), -1)
        }
    }

    func testSplits() {
        let names = manager.splits
        XCTAssertEqual(names.count, 5)
        for i in 1 ... 5 {
            XCTAssertNotEqual(indexForSplit(name: "s\(i)", array: names), -1)
        }
    }

    func testSplitsByName() {
        for i in 1 ... 5 {
            XCTAssertNotNil(manager.split(featureName: "s\(i)"))
        }

        for i in 10 ... 15 {
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

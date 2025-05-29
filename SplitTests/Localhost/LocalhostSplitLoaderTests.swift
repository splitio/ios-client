//
//  LocalhostSplitFetcherTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/02/2018.
//  Copyright © 2018 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostSplitLoaderTests: XCTestCase {
    var storage: FileStorage!
    var eventsManager: SplitEventsManagerMock!
    var fileLoader: FeatureFlagsFileLoader!

    override func setUp() {
        storage = FileStorageStub()
    }

    func loadSplits(loader: FeatureFlagsFileLoader) -> [String: Split] {
        var splits: [String: Split]?
        let exp = XCTestExpectation()
        loader.loadHandler = {
            splits = $0
            exp.fulfill()
        }
        loader.start()
        wait(for: [exp], timeout: 5.0)
        loader.stop()
        return splits ?? [:]
    }

    func testInitial() {
        let loader = try! sourceFor(fileName: "localhost.splits")
        let splits = loadSplits(loader: loader)

        XCTAssertEqual(splits.count, 5)
        for i in 1 ... 5 {
            XCTAssertEqual(splits["s\(i)"]?.name, "s\(i)")
        }
    }

    func testFileUpdate() {
        let fileName = "localhost.splits"
        let fileContent = """
        s5 t5\n
        s6 t6\n
        s7 t7
        """
        let loader = try! sourceFor(fileName: fileName)
        storage.write(fileName: fileName, content: fileContent)
        let splits = loadSplits(loader: loader)
        XCTAssertEqual(splits.count, 3)
        for i in 5 ... 7 {
            XCTAssertEqual(splits["s\(i)"]?.name, "s\(i)")
        }
    }

    func testFileUpdate2() {
        let fileName = "localhost.splits"
        let loader = try! sourceFor(fileName: fileName)
        let fileContent = """
        s5 t5\n
        s6 t6\n
        s7 t7\n
        s8 t8
        """
        storage.write(fileName: fileName, content: fileContent)
        let splits = loadSplits(loader: loader)
        XCTAssertEqual(splits.count, 4)
        for i in 5 ... 8 {
            XCTAssertEqual(splits["s\(i)"]?.name, "s\(i)")
        }
    }

    func testWrongLegacyFormatUpdate() {
        let fileName = "localhost.splits"
        let loader = try! sourceFor(fileName: fileName)
        var splits = loadSplits(loader: loader)
        let originalCount = splits.count
        let fileContent =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        splits = loadSplits(loader: loader)

        XCTAssertEqual(5, originalCount)
        XCTAssertEqual(splits.count, 0)
    }

    func testWrongYamlFormatUpdate() {
        let fileName = "localhost.yaml"
        let loader = try! sourceFor(fileName: fileName)
        var splits = loadSplits(loader: loader)
        let originalCount = splits.count
        let fileContent =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean tempus dolor sed orci convallis, in tincidunt risus maximus. Praesent ipsum dui, aliquam in quam alique"
        storage.write(fileName: fileName, content: fileContent)
        splits = loadSplits(loader: loader)

        XCTAssertEqual(9, originalCount)
        XCTAssertEqual(splits.count, 0)
    }

    func testInvalidTypeFile() {
        var err = false
        do {
            let _ = try sourceFor(fileName: "splits.txt")
        } catch {
            err = true
        }

        XCTAssertTrue(err)
    }

    func testNonExistingFile() {
        var err = false
        do {
            let _ = try sourceFor(fileName: "non_existing_splits.yaml")
        } catch {
            err = true
        }
        XCTAssertTrue(err)
    }

    func testWrongFormatYml() {
        let loader = try! sourceFor(fileName: "wrong_format.yaml")
        let splits = loadSplits(loader: loader)
        XCTAssertEqual(0, splits.count)
    }

    func sourceFor(fileName: String) throws -> FeatureFlagsFileLoader {
        var config = FeatureFlagsFileLoaderConfig()
        config.refreshInterval = 1
        return try FeatureFlagsFileLoader(
            fileStorage: storage,
            config: config,
            dataFolderName: "localhost",
            splitsFileName: fileName,
            bundle: Bundle(for: type(of: self)))
    }
}

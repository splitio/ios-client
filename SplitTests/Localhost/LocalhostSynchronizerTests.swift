//
//  LocalhostSynchronizerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 09/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostSynchronizerTests: XCTestCase {
    var synchronizer: LocalhostSynchronizer!

    let storage = SplitsStorageStub()
    let eventsManager = SplitEventsManagerMock()
    let datasource = LocalhostApiDataSource()

    var yamlContent: String!
    var splitsContent: String!

    override func setUp() {
        yamlContent = FileHelper.readDataFromFile(sourceClass: self, name: "localhost", type: "yaml")
        splitsContent = FileHelper.readDataFromFile(sourceClass: self, name: "localhost", type: "splits")

        synchronizer = createSynchronizer()
    }

    func createSynchronizer() -> LocalhostSynchronizer {
        return LocalhostSynchronizer(
            featureFlagsStorage: storage,
            featureFlagsDataSource: datasource,
            eventsManager: eventsManager)
    }

    func testLoadAndSdkReady() {
        eventsManager.isSplitsReadyFired = false
        let storage = SplitsStorageStub()
        let eventsManager = SplitEventsManagerMock()
        let datasource = LocalhostApiDataSource()

        let sync = LocalhostSynchronizer(
            featureFlagsStorage: storage,
            featureFlagsDataSource: datasource,
            eventsManager: eventsManager)

        let prevSdkReady = eventsManager.isSplitsReadyFired
        datasource.update(yaml: yamlContent)
        XCTAssertFalse(prevSdkReady)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)

        sync.destroy()
    }

    func testUpdateYaml() {
        eventsManager.isSplitUpdatedTriggered = false
        let splitsEmpty = storage.getAll()
        datasource.update(yaml: yamlContent)
        let splits = storage.getAll()

        XCTAssertEqual(0, splitsEmpty.count)
        XCTAssertEqual(9, splits.count)
        XCTAssertTrue(eventsManager.isSplitUpdatedTriggered)
    }

    func testUpdateSplits() {
        eventsManager.isSplitUpdatedTriggered = false
        let splitsEmpty = storage.getAll()
        datasource.update(splits: splitsContent)
        let splits = storage.getAll()

        XCTAssertEqual(0, splitsEmpty.count)
        XCTAssertEqual(5, splits.count)
        XCTAssertTrue(eventsManager.isSplitUpdatedTriggered)
    }
}

//
//  SplitClientManagerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 21-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitClientManagerTest: XCTestCase {

    var clientManager: SplitClientManager!
    var config: SplitClientConfig! = SplitClientConfig()
    var byKeyFacade: ByKeyFacadeStub!
    var syncManager: SyncManagerStub!
    var splitEventsCoordinator: SplitEventsManagerCoordinatorStub!
    var synchronizer: SynchronizerStub!
    let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
    var telemetryProducer: TelemetryStorageStub!
    var splitManager: SplitManagerStub!
    var stopwatch = Stopwatch()
    let newKey = "new_key"

    override func setUp() {
        config = SplitClientConfig()
        byKeyFacade = ByKeyFacadeStub()
        syncManager = SyncManagerStub()
        splitEventsCoordinator = SplitEventsManagerCoordinatorStub()
        synchronizer = SynchronizerStub()
        createClientManager()
    }

    func testInit() {

        XCTAssertEqual(1, byKeyFacade.matchingKeys.count)
        XCTAssertTrue(syncManager.startCalled)
        XCTAssertNotNil(clientManager.defaultClient)
        XCTAssertEqual(1, byKeyFacade.components.count)
        // This should not be called on init
        XCTAssertFalse(synchronizer.startForKeyCalled[key] ?? false)
        XCTAssertNotNil(byKeyFacade.components[key])
        XCTAssertTrue(splitEventsCoordinator.startCalled)
    }

    func testAddClient() {
        let newKey = Key(matchingKey: newKey)
        let client = clientManager.get(forKey: newKey)

        XCTAssertNotNil(client)
        XCTAssertEqual(2, byKeyFacade.matchingKeys.count)
        XCTAssertEqual(2, byKeyFacade.components.count)
        // This should not be called on init
        XCTAssertTrue(synchronizer.startForKeyCalled[newKey] ?? false)
        XCTAssertNotNil(byKeyFacade.components[newKey])
        XCTAssertTrue(syncManager.resetStreamingCalled)
    }

    func testDestroyForKey() {
        let thisKey = Key(matchingKey: newKey)
        // Calling get to create a new client
        _ = clientManager.get(forKey: thisKey)

        sleep(1)
        clientManager.destroy(forKey: thisKey)

        XCTAssertFalse(byKeyFacade.destroyCalled)
        XCTAssertEqual(1, byKeyFacade.components.count)
        XCTAssertNil(byKeyFacade.components[Key(matchingKey: newKey)])
        XCTAssertFalse(byKeyFacade.destroyCalled)
    }

    func testDestroyLastKey() {

        sleep(1)
        clientManager.destroy(forKey: key)

        // XCTAssertTrue(byKeyFacade.destroyCalled) It's destroyed by the syncrhonizer
        XCTAssertEqual(0, byKeyFacade.components.count)
        XCTAssertNil(byKeyFacade.components[key])
        XCTAssertTrue(synchronizer.flushCalled)
        XCTAssertTrue(syncManager.stopCalled)
        XCTAssertTrue(splitManager.destroyCalled)
        XCTAssertTrue(telemetryProducer.recordSessionLengthCalled)
    }

    func testFlush() {
        clientManager.flush()

        XCTAssertTrue(synchronizer.flushCalled)
    }

    private func createClientManager() {
        let splitDatabase = TestingHelper.createTestDatabase(name: UUID().uuidString)
        let apiFacade = TestingHelper.createApiFacade()

        splitManager = SplitManagerStub()
        telemetryProducer = TelemetryStorageStub()
        let storageContainer = try! SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: config, apiKey: IntegrationHelper.dummyApiKey,
            userKey: key.matchingKey, databaseName: "dummy",
            telemetryStorage: telemetryProducer, testDatabase: splitDatabase)
        clientManager = DefaultClientManager(config: config,
                                             key: key,
                                             splitManager: splitManager,
                                             apiFacade: apiFacade,
                                             byKeyFacade: byKeyFacade,
                                             storageContainer: storageContainer,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsTracker: EventsTrackerStub(),
                                             eventsManagerCoordinator: splitEventsCoordinator,
                                             mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactoryStub(),
                                             telemetryStopwatch: stopwatch, factory: SplitFactoryStub(apiKey: IntegrationHelper.dummyApiKey))
    }

    override func tearDown() {
    }
}


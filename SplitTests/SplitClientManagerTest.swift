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
        XCTAssertEqual(1, byKeyFacade.keys.count)
        XCTAssertTrue(syncManager.startCalled)
        XCTAssertNotNil(clientManager.defaultClient)
        XCTAssertEqual(1, byKeyFacade.components.count)
        // This should not be called on init
        XCTAssertFalse(synchronizer.startForKeyCalled[key.matchingKey] ?? false)
        XCTAssertNotNil(byKeyFacade.components[key.matchingKey])
        XCTAssertTrue(splitEventsCoordinator.startCalled)
    }

    func testAddClient() {

        let client = clientManager.get(forKey: Key(matchingKey: newKey))

        XCTAssertNotNil(client)
        XCTAssertEqual(2, byKeyFacade.keys.count)
        XCTAssertEqual(2, byKeyFacade.components.count)
        // This should not be called on init
        XCTAssertTrue(synchronizer.startForKeyCalled[newKey] ?? false)
        XCTAssertNotNil(byKeyFacade.components[newKey])
        XCTAssertTrue(syncManager.resetStreamingCalled)
    }

    func testDestroyForKey() {

        // Calling get to create a new client
        _ = clientManager.get(forKey: Key(matchingKey: newKey))

        sleep(1)
        clientManager.destroy(forKey: newKey)

        XCTAssertFalse(byKeyFacade.destroyCalled)
        XCTAssertEqual(1, byKeyFacade.components.count)
        XCTAssertNil(byKeyFacade.components[newKey])
        XCTAssertFalse(byKeyFacade.destroyCalled)
    }

    func testDestroyLastKey() {

        sleep(1)
        clientManager.destroy(forKey: key.matchingKey)

        // XCTAssertTrue(byKeyFacade.destroyCalled) It's destroyed by the syncrhonizer
        XCTAssertEqual(0, byKeyFacade.components.count)
        XCTAssertNil(byKeyFacade.components[key.matchingKey])
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
        let apiFacade = SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()

        splitManager = SplitManagerStub()
        telemetryProducer = TelemetryStorageStub()
        let storageContainer = try! SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: config,
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
                                             eventsManagerCoordinator: splitEventsCoordinator,
                                             mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactoryStub(),
                                             telemetryStopwatch: stopwatch)
    }

    override func tearDown() {
    }
}


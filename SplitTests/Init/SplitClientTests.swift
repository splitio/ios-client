//
//  SplitClientTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/04/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitClientTests: XCTestCase {

    var client: SplitClient!
    let key = Key(matchingKey: "key1")
    var treatmentManager: TreatmentManager!
    var apiFacade: SplitApiFacade!
    var storageContainer: SplitStorageContainer!
    var eventsManager: SplitEventsManagerMock!
    var eventsTracker: EventsTrackerStub!
    var clientManager: ClientManagerMock!
    let events: [SplitEvent] = [.sdkReadyFromCache, .sdkReady, .sdkUpdated, .sdkReadyTimedOut]

    override func setUp() {
        storageContainer = TestingHelper.createStorageContainer()
        eventsManager = SplitEventsManagerMock()
        clientManager = ClientManagerMock()
        treatmentManager = TreatmentManagerMock()
        apiFacade = TestingHelper.createApiFacade()
        let config = SplitClientConfig()
        config.logLevel = .verbose
        eventsTracker = EventsTrackerStub()

        client = DefaultSplitClient(config: config, key: key,
                                    treatmentManager: treatmentManager, apiFacade: apiFacade,
                                    storageContainer: storageContainer,
                                    eventsManager: eventsManager,
                                    eventsTracker: eventsTracker, clientManager: clientManager)
    }

    func testOnMain() {
        for event in events {
            client.on(event: event, execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents[event] else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(false, task.runInBackground)
            XCTAssertNil(task.takeQueue())
        }
    }

    func testOnBg() {
        for event in events {
            client.on(event: event, runInBackground: true, execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents[event] else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(true, task.runInBackground)
            XCTAssertNil(task.takeQueue())
        }
    }

    func testOnQueue() {
        for event in events {
            client.on(event: event, queue: DispatchQueue(label: "queue1"), execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents[event] else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(true, task.runInBackground)
            XCTAssertNotNil(task.takeQueue())
        }
    }

    override func tearDown() {
    }
}


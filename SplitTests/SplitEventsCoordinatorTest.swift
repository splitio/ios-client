//
//  SplitEventsCoordinatorTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SplitEventsCoordinatorTest: XCTestCase {
    var coordinator: SplitEventsManagerCoordinator!

    override func setUp() {
        coordinator = MainSplitEventsManager()
    }

    func testAddNotifyRemoveManager() {
        let manager1 = SplitEventsManagerStub()
        let manager2 = SplitEventsManagerStub()
        let manager3 = SplitEventsManagerStub()

        coordinator.add(manager1, forKey: buildKey("k1"))
        coordinator.add(manager2, forKey: buildKey("k2"))
        coordinator.add(manager3, forKey: buildKey("k3"))

        coordinator.remove(forKey: buildKey("k3"))

        sleep(1)

        XCTAssertTrue(manager1.startCalled)
        XCTAssertTrue(manager2.startCalled)
        XCTAssertTrue(manager3.startCalled)

        XCTAssertFalse(manager1.stopCalled)
        XCTAssertFalse(manager2.stopCalled)
        XCTAssertTrue(manager3.stopCalled)
    }

    func testEventsAfterAdd() {
        let count = 3
        let managers = addManagersToCoordinator(count: count)

        coordinator.notifyInternalEvent(.splitsLoadedFromCache)
        coordinator.notifyInternalEvent(.splitsUpdated)
        coordinator.notifyInternalEvent(.splitKilledNotification)

        sleep(1)

        for i in 0 ..< count {
            XCTAssertEqual(1, managers[i].splitsLoadedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsUpdatedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsKilledEventFiredCount)
        }
    }

    func testEventsBeforeAdd() {
        let count = 3
        coordinator.notifyInternalEvent(.splitsLoadedFromCache)
        coordinator.notifyInternalEvent(.splitsUpdated)
        coordinator.notifyInternalEvent(.splitKilledNotification)

        let managers = addManagersToCoordinator(count: count)

        sleep(1)

        for i in 0 ..< count {
            XCTAssertEqual(1, managers[i].splitsLoadedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsUpdatedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsKilledEventFiredCount)
        }
    }

    func testEventsAfterRemove() {
        let count = 3

        let managers = addManagersToCoordinator(count: count)

        coordinator.remove(forKey: buildKey("k0"))
        coordinator.remove(forKey: buildKey("k1"))
        coordinator.remove(forKey: buildKey("k2"))

        sleep(1)

        coordinator.notifyInternalEvent(.splitsLoadedFromCache)
        coordinator.notifyInternalEvent(.splitsUpdated)
        coordinator.notifyInternalEvent(.splitKilledNotification)

        sleep(1)

        for i in 0 ..< count {
            XCTAssertEqual(0, managers[i].splitsLoadedEventFiredCount)
            XCTAssertEqual(0, managers[i].splitsUpdatedEventFiredCount)
            XCTAssertEqual(0, managers[i].splitsKilledEventFiredCount)
        }
    }

    func testStop() {
        var managers = [SplitEventsManagerStub]()
        for i in 0 ..< 10 {
            let manager = SplitEventsManagerStub()
            managers.append(manager)
            coordinator.add(manager, forKey: buildKey("k\(i)"))
        }
        coordinator.stop()
        sleep(1)
        for manager in managers {
            XCTAssertTrue(manager.stopCalled)
        }
    }

    private func addManagersToCoordinator(count: Int) -> [SplitEventsManagerStub] {
        var managers = [SplitEventsManagerStub]()
        for i in 0 ..< count {
            let manager = SplitEventsManagerStub()
            managers.append(manager)
            coordinator.add(manager, forKey: buildKey("k\(i)"))
        }
        return managers
    }

    private func buildKey(_ matchingKey: String) -> Key {
        return Key(matchingKey: matchingKey)
    }

    override func tearDown() {}
}

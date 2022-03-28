//
//  SplitEventsCoordinatorTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitEventsCoordinatorTest: XCTestCase {

    var coordinator: SplitEventsManagerCoordinator!

    override func setUp() {
        coordinator = GlobalEventsQueue()
    }

    func testAddNotifyRemoveManager() {
        let manager1 = SplitEventsManagerStub()
        let manager2 = SplitEventsManagerStub()
        let manager3 = SplitEventsManagerStub()

        coordinator.add(manager1, forKey: "k1")
        coordinator.add(manager2, forKey: "k2")
        coordinator.add(manager3, forKey: "k3")

        coordinator.remove(forKey: "k3")

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

        for i in 0..<count {
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

        for i in 0..<count {
            XCTAssertEqual(1, managers[i].splitsLoadedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsUpdatedEventFiredCount)
            XCTAssertEqual(1, managers[i].splitsKilledEventFiredCount)
        }
    }

    func testEventsAfterRemove() {
        let count = 3

        let managers = addManagersToCoordinator(count: count)

        coordinator.remove(forKey: "k0")
        coordinator.remove(forKey: "k1")
        coordinator.remove(forKey: "k2")

        sleep(1)

        coordinator.notifyInternalEvent(.splitsLoadedFromCache)
        coordinator.notifyInternalEvent(.splitsUpdated)
        coordinator.notifyInternalEvent(.splitKilledNotification)

        sleep(1)

        for i in 0..<count {
            XCTAssertEqual(0, managers[i].splitsLoadedEventFiredCount)
            XCTAssertEqual(0, managers[i].splitsUpdatedEventFiredCount)
            XCTAssertEqual(0, managers[i].splitsKilledEventFiredCount)
        }
    }


    private func addManagersToCoordinator(count: Int) -> [SplitEventsManagerStub] {
        var managers = [SplitEventsManagerStub]()
        for i in 0..<count {
            let manager = SplitEventsManagerStub()
            managers.append(manager)
            coordinator.add(manager, forKey: "k\(i)")
        }
        return managers
    }




    override func tearDown() {
    }
}


//
//  SplitEventsManagerCoordinatorStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 21-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split

class SplitEventsManagerCoordinatorStub: SplitEventsManagerCoordinator {

    var managers = [Key: SplitEventsManager]()

    func add(_ manager: SplitEventsManager, forKey key: Key) {
        managers[key] = manager
    }

    func remove(forKey key: Key) {
        managers[key] = nil
    }

    func register(event: SplitEvent, task: SplitEventActionTask) {

    }
    
    func register(event: SplitEventWithMetadata, task: SplitEventActionTask) {}

    func notifyInternalEvent(_ event: SplitInternalEvent, metadata: EventMetadata?) {}

    var notifiedEvents = Set<String>()
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        notifiedEvents.insert(IntegrationHelper.describeEvent(event))
    }

    var startCalled = false
    func start() {
        startCalled = true
    }

    var stopCalled = false
    func stop() {
        stopCalled = true
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return false
    }
}


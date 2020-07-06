//
// SplitEventsManagerStub.swift
// Split
//
// Created by Javier L. Avrudsky on 05/05/2020.
// Copyright (c) 2020  All rights reserved.
//

import Foundation
@testable import Split
class SplitEventsManagerStub: SplitEventsManager {
    func notifyInternalEvent(_ event: SplitInternalEvent) {

    }

    func getExecutorResources() -> SplitEventExecutorResources {
        fatalError("getExecutorResources() has not been implemented")
    }

    func register(event: SplitEvent, task: SplitEventTask) {
    }

    func start() {
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return false
    }

    func getExecutionTimes() -> [String: Int] {
        return [String: Int]()
    }
}

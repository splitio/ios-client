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
    var splitsLoadedEventFiredCount = 0
    var mySegmentsLoadedEventFiredCount = 0
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        switch event {
        case .mySegmentsLoadedFromCache:
            mySegmentsLoadedEventFiredCount+=1
        case .splitsLoadedFromCache:
            splitsLoadedEventFiredCount+=1
        default:
            print("internal event fired: \(event)")
        }
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

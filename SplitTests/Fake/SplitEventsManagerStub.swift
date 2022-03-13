//
// SplitEventsManagerStub.swift
// Split
//
// Created by Javier L. Avrudsky on 05/05/2020.
// Copyright (c) 2020  All rights reserved.
//

import Foundation
@testable import Split
import XCTest
class SplitEventsManagerStub: SplitEventsManager {

    var splitsLoadedEventFiredCount = 0
    var executorResources: SplitEventExecutorResources = SplitEventExecutorResources()
    var mySegmentsLoadedEventFiredCount = 0
    var mySegmentsLoadedEventExp: XCTestExpectation?
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        switch event {
        case .mySegmentsLoadedFromCache:
            mySegmentsLoadedEventFiredCount+=1
            if let exp = mySegmentsLoadedEventExp {
                exp.fulfill()
            }
        case .splitsLoadedFromCache:
            splitsLoadedEventFiredCount+=1
        default:
            print("internal event fired: \(event)")
        }
    }

    func register(event: SplitEvent, task: SplitEventTask) {
    }

    func start() {
    }

    func stop() {
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return false
    }
}

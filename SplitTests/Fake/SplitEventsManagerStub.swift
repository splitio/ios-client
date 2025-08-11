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
    var splitsKilledEventFiredCount = 0
    var splitsUpdatedEventFiredCount = 0
    var mySegmentsLoadedEventFiredCount = 0
    var mySegmentsLoadedEventExp: XCTestExpectation?
    var startCalled = false
    var stopCalled = false

    func notifyInternalEvent(_ event: SplitInternalEvent) {
        switch event {
        case .mySegmentsLoadedFromCache:
            mySegmentsLoadedEventFiredCount+=1
            if let exp = mySegmentsLoadedEventExp {
                exp.fulfill()
            }
        case .splitsLoadedFromCache:
            splitsLoadedEventFiredCount+=1

        case .splitKilledNotification:
            splitsKilledEventFiredCount+=1

        case .splitsUpdated:
            splitsUpdatedEventFiredCount+=1
        default:
            print("internal event fired: \(event)")
        }
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        register(event: SplitEventWithMetadata(type: event, metadata: nil), task: task)
    }

    var registeredEvents = [SplitEventWithMetadata: SplitEventTask]()
    func register(event: SplitEventWithMetadata, task: SplitEventTask) {
        registeredEvents[event] = task
    }

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return false
    }
}
